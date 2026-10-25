plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aitasadduq.arabic_ocr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.aitasadduq.arabic_ocr"
        // Android 9+: the same floor as the upstream Nuqta app (64-bit, ~2 GB free RAM).
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // 64-bit only: the model needs more address space than 32-bit ARM offers.
        // x86_64 is for emulators. (--split-per-abi sets its own ABI list.)
        if (!project.hasProperty("split-per-abi")) {
            ndk { abiFilters += listOf("arm64-v8a", "x86_64") }
        }
    }

    // Keep native libraries extracted: the OCR engine picks the best CPU backend
    // for the phone by scanning its library directory at run time.
    packaging { jniLibs { useLegacyPackaging = true } }

    buildTypes {
        release {
            // Signed with the debug key so CI builds install directly; use your own key to publish.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
