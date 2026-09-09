allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // android-37 SDK is not yet publicly available, but some plugins (e.g.
    // flutter_secure_storage 11.0.0) hardcode compileSdk = 37. Pin every Android
    // library subproject to compileSdk 36 so it builds with the installed SDK.
    // Registered before evaluationDependsOn so it is not too late to add.
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            val current = compileSdk
            if (current != null && current > 36) {
                compileSdk = 36
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
