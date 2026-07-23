allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val sharedBuildDirectory: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(sharedBuildDirectory)

subprojects {
    val subprojectBuildDirectory: Directory = sharedBuildDirectory.dir(project.name)
    project.layout.buildDirectory.value(subprojectBuildDirectory)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
