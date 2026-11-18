plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigning = listOf(
    "ERP_KEYSTORE", "ERP_KEYSTORE_PASSWORD", "ERP_KEY_ALIAS", "ERP_KEY_PASSWORD",
).associateWith { System.getenv(it) }

android {
    namespace = "com.wutongpuli.garment_erp_android"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.wutongpuli.garment_erp_android"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (releaseSigning.values.any { !it.isNullOrBlank() }) {
        require(releaseSigning.values.all { !it.isNullOrBlank() }) {
            "Set all four ERP signing variables for a release build."
        }
        signingConfigs.create("erpRelease") {
            storeFile = file(releaseSigning.getValue("ERP_KEYSTORE")!!)
            storePassword = releaseSigning.getValue("ERP_KEYSTORE_PASSWORD")
            keyAlias = releaseSigning.getValue("ERP_KEY_ALIAS")
            keyPassword = releaseSigning.getValue("ERP_KEY_PASSWORD")
        }
        buildTypes.getByName("release").signingConfig = signingConfigs.getByName("erpRelease")
    }
}

dependencies {
    implementation("androidx.core:core:1.13.1")
}

flutter {
    source = "../.."
}
