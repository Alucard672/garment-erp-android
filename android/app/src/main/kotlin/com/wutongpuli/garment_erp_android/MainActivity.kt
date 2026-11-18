package com.wutongpuli.garment_erp_android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val updates = AppUpdates(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "garment_erp/app_updates")
            .setMethodCallHandler(updates::handle)
    }
}
