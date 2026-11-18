package com.wutongpuli.garment_erp_android

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.URI
import java.security.MessageDigest
import javax.net.ssl.HttpsURLConnection

@Suppress("DEPRECATION")
internal class AppUpdates(private val activity: MainActivity) {
    private data class Release(
        val code: Long, val name: String, val url: URI, val sha256: String, val bytes: Long,
    )

    private val manager get() = activity.packageManager
    private val signatureFlag get() = if (Build.VERSION.SDK_INT >= 28) {
        PackageManager.GET_SIGNING_CERTIFICATES
    } else PackageManager.GET_SIGNATURES
    private val current get() = manager.getPackageInfo(activity.packageName, signatureFlag)
    private val directory get() = File(activity.cacheDir, "app-update")
    private val apk get() = File(directory, "update.apk")
    private var candidate: Release? = null
    private var downloaded: Release? = null
    private var busy = false

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (busy) {
            result.error("busy", "正在处理更新，请稍等。", null)
            return
        }
        when (call.method) {
            "version" -> result.success(mapOf("name" to current.versionName, "code" to version(current)))
            "check", "probe" -> {
                val prepareDownload = call.method == "check"
                if (prepareDownload) {
                    candidate = null
                    downloaded = null
                }
                worker(result, exclusive = prepareDownload) {
                    val release = check(call.argument<String>("url").orEmpty())
                    if (prepareDownload) candidate = release
                    release?.let { mapOf("name" to it.name, "code" to it.code, "bytes" to it.bytes) }
                }
            }
            "download" -> {
                val release = candidate
                if (release == null) {
                    result.error("no_update", "请先检查更新。", null)
                } else {
                    worker(result) {
                        download(release)
                        downloaded = release
                        null
                    }
                }
            }
            "install" -> install(result)
            else -> result.notImplemented()
        }
    }

    private fun worker(result: MethodChannel.Result, exclusive: Boolean = true, task: () -> Any?) {
        if (exclusive) busy = true
        Thread {
            val outcome = runCatching(task)
            activity.runOnUiThread {
                if (exclusive) busy = false
                outcome.fold(
                    onSuccess = result::success,
                    onFailure = {
                        val message = if (it is IllegalArgumentException) it.message else null
                        result.error("update_failed", message ?: "更新连接或下载失败，请稍后重试。", null)
                    },
                )
            }
        }.start()
    }

    private fun check(url: String): Release? {
        val manifest = URI(url)
        require(manifest.scheme == "https" && manifest.host != null && manifest.userInfo == null) {
            "更新地址必须使用 HTTPS。"
        }
        val response = fetch(manifest) { stream ->
            val json = ByteArrayOutputStream()
            val buffer = ByteArray(4096)
            while (true) {
                val count = stream.read(buffer)
                if (count < 0) break
                require(json.size() + count <= 65536) { "版本清单过大。" }
                json.write(buffer, 0, count)
            }
            JSONObject(json.toString("UTF-8"))
        }
        val code = response.getLong("versionCode")
        val name = response.getString("versionName")
        val filename = response.getString("apk")
        val sha256 = response.getString("sha256")
        val bytes = response.getLong("bytes")
        require(
            code in 1..2100000000 && name.isNotBlank() && name.length <= 80 &&
                filename.matches(Regex("[A-Za-z0-9][A-Za-z0-9._-]{0,99}\\.apk")) &&
                sha256.matches(Regex("[a-f0-9]{64}")) && bytes in 1..536870912
        ) { "版本清单内容不正确。" }
        if (code <= version(current)) return null
        return Release(code, name, manifest.resolve(filename), sha256, bytes)
    }

    private fun download(release: Release) {
        check(directory.mkdirs() || directory.isDirectory)
        val partial = File(directory, "download.apk")
        apk.delete()
        val digest = MessageDigest.getInstance("SHA-256")
        try {
            fetch(release.url) { stream ->
                var total = 0L
                val buffer = ByteArray(65536)
                partial.outputStream().use { file ->
                    while (true) {
                        val count = stream.read(buffer)
                        if (count < 0) break
                        total += count
                        require(total <= release.bytes) { "APK 大小与版本清单不符。" }
                        digest.update(buffer, 0, count)
                        file.write(buffer, 0, count)
                    }
                }
                require(total == release.bytes) { "APK 下载不完整。" }
            }
            val hash = digest.digest().joinToString("") { "%02x".format(it) }
            require(hash == release.sha256) { "APK 校验失败，请重新下载。" }
            val incoming = manager.getPackageArchiveInfo(partial.path, signatureFlag)
            val installed = current
            require(incoming != null && incoming.packageName == activity.packageName &&
                version(incoming) == release.code && version(incoming) > version(installed)
            ) { "APK 包名或版本号不匹配。" }
            val installedSignatures = signatures(installed)
            require(installedSignatures.isNotEmpty() && installedSignatures == signatures(incoming)) {
                "新版 APK 与当前 App 的签名不同。"
            }
            check(partial.renameTo(apk))
        } finally {
            partial.delete()
        }
    }

    private fun install(result: MethodChannel.Result) {
        if (downloaded == null || !apk.isFile) {
            result.error("no_apk", "请重新下载更新包。", null)
            return
        }
        try {
            if (Build.VERSION.SDK_INT >= 26 && !manager.canRequestPackageInstalls()) {
                activity.startActivity(Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${activity.packageName}"),
                ))
                result.success(false)
                return
            }
            val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", apk)
            activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            })
            result.success(true)
        } catch (_: Exception) {
            result.error("installer_unavailable", "无法打开 Android 安装页面。", null)
        }
    }

    private fun version(info: PackageInfo) =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    private fun signatures(info: PackageInfo) =
        (if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures)
            ?.toSet().orEmpty()

    private fun <T> fetch(url: URI, use: (java.io.InputStream) -> T): T {
        val connection = url.toURL().openConnection() as HttpsURLConnection
        return try {
            connection.instanceFollowRedirects = false
            connection.useCaches = false
            connection.connectTimeout = 10000
            connection.readTimeout = 20000
            require(connection.responseCode == 200) { "更新服务器暂时无法提供文件。" }
            connection.inputStream.use(use)
        } finally {
            connection.disconnect()
        }
    }
}
