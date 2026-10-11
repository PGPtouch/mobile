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
    afterEvaluate {
        val androidExtension = extensions.findByType<com.android.build.gradle.BaseExtension>()
        if (androidExtension != null) {
            if (androidExtension.namespace == null) {
                val manifestFile = androidExtension.sourceSets.getByName("main").manifest.srcFile
                val parsedManifest = groovy.xml.XmlSlurper().parse(manifestFile)
                androidExtension.namespace = parsedManifest.getProperty("@package").toString()
            }
            androidExtension.compileSdkVersion(37)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
