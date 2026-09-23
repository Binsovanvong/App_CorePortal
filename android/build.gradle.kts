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
        val extension = project.extensions.findByName("android") ?: return@afterEvaluate
        try {
            val getNamespaceMethod = extension.javaClass.getMethod("getNamespace")
            val currentNamespace = getNamespaceMethod.invoke(extension) as? String
            if (currentNamespace.isNullOrBlank()) {
                val setNamespaceMethod = extension.javaClass.getMethod("setNamespace", String::class.java)
                val fallbackNamespace = if (project.name == "flutter_jailbreak_detection") {
                    "appmire.be.flutterjailbreakdetection"
                } else {
                    "com.example.${project.name.replace('-', '_')}"
                }
                setNamespaceMethod.invoke(extension, fallbackNamespace)
            }
        } catch (e: Exception) {
            // Ignore if method does not exist
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
