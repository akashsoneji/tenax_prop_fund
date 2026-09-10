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
    val pinCompileSdk: Project.() -> Unit = {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            val current = compileSdk
            if (current != null && current > 36) {
                compileSdk = 36
            }
        }
    }
    // evaluationDependsOn(":app") can force a sibling project to evaluate before
    // this loop reaches it; on Gradle 8.14+ registering afterEvaluate on an
    // already-evaluated project throws, so apply directly in that case.
    if (project.state.executed) {
        project.pinCompileSdk()
    } else {
        afterEvaluate { pinCompileSdk() }
    }
    if (project.path != ":app") {
        project.evaluationDependsOn(":app")
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
