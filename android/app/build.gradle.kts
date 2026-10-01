plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tenax.tenax_prop_flutter"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tenax.tenax_prop_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 14 (API 34) and later only.
        minSdk = 34
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }

    buildFeatures {
        resValues = true
    }

    flavorDimensions += "client"
    productFlavors {
        create("tenax") {
            dimension = "client"
            // Base flavor keeps the root application id.
            resValue("string", "app_name", "Tenax Prop")
        }
        create("pipze_funded") {
            dimension = "client"
            applicationIdSuffix = ".pipzefunded"
            resValue("string", "app_name", "Pipze Funded")
        }
        create("alibabafx_prop") {
            dimension = "client"
            applicationIdSuffix = ".alibabafxprop"
            resValue("string", "app_name", "AlibabaFX Prop")
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
