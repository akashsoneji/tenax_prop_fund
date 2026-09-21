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
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
        create("client_a") {
            dimension = "client"
            applicationIdSuffix = ".clienta"
            resValue("string", "app_name", "Client A")
        }
        create("client_b") {
            dimension = "client"
            applicationIdSuffix = ".clientb"
            resValue("string", "app_name", "Client B")
        }
        create("client_c") {
            dimension = "client"
            applicationIdSuffix = ".clientc"
            resValue("string", "app_name", "Client C")
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
