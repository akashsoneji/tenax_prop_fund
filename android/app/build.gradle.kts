import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Each flavor is its own Play listing, so each has its own upload keystore at
// android/keystore/<flavor>/key.properties (+ the .jks it names). Both are
// gitignored; when missing, release falls back to the debug key, which Play
// rejects on upload.
val clientFlavors = listOf("tenax", "pipze_funded", "alibabafx_prop", "pipprop")

fun loadKeystoreProperties(flavor: String): Properties? {
    val file = rootProject.file("keystore/$flavor/key.properties")
    if (!file.exists()) return null
    return Properties().apply { file.inputStream().use { load(it) } }
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

    signingConfigs {
        clientFlavors.forEach { flavor ->
            val props = loadKeystoreProperties(flavor) ?: return@forEach
            create(flavor) {
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
                storeFile = rootProject.file("keystore/$flavor/${props.getProperty("storeFile")}")
                storePassword = props.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }

    // Debug builds keep the debug key: the debug buildType's own signingConfig
    // takes precedence over the flavor's.
    fun releaseSigningFor(flavor: String) =
        signingConfigs.findByName(flavor) ?: signingConfigs.getByName("debug")

    buildFeatures {
        resValues = true
    }

    flavorDimensions += "client"
    productFlavors {
        create("tenax") {
            dimension = "client"
            // Base flavor keeps the root application id.
            resValue("string", "app_name", "Tenax Prop")
            signingConfig = releaseSigningFor("tenax")
        }
        create("pipze_funded") {
            dimension = "client"
            applicationIdSuffix = ".pipzefunded"
            resValue("string", "app_name", "Pipze Funded")
            // Still distributed as a sideloaded APK that self-updates over the
            // installs already in the field, which were signed with the debug
            // key. Android refuses an update signed by a different key, so keep
            // the debug key until this flavor moves to Play.
            signingConfig = signingConfigs.getByName("debug")
        }
        create("alibabafx_prop") {
            dimension = "client"
            applicationIdSuffix = ".alibabafxprop"
            resValue("string", "app_name", "AlibabaFX Prop")
            signingConfig = releaseSigningFor("alibabafx_prop")
        }
        create("pipprop") {
            dimension = "client"
            // Own application id: installs alongside pipze_funded as a separate app.
            applicationId = "com.pipprop.app"
            resValue("string", "app_name", "Pip Prop")
            signingConfig = releaseSigningFor("pipprop")
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
