import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "kh.gov.interior.core.prod"
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
        applicationId = "kh.gov.interior.core.prod"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            val rawStorePath = keystoreProperties.getProperty("storeFile")
            if (rawStorePath != null) {
                val candidateFile = file(rawStorePath)
                storeFile = if (candidateFile.exists()) {
                    candidateFile
                } else {
                    rootProject.file(rawStorePath)
                }
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (keystorePropertiesFile.exists() && releaseSigning.storeFile?.exists() == true) {
                releaseSigning
            } else {
                // Graceful fallback to debug signing if release key is not configured locally
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Ensure AGP bundle packaging completes before IDE model listing checks for the .aab artifact
tasks.matching { it.name == "produceReleaseBundleIdeListingFile" }.configureEach {
    mustRunAfter(tasks.matching { it.name == "packageReleaseBundle" || it.name == "signReleaseBundle" })
    dependsOn(tasks.matching { it.name == "packageReleaseBundle" || it.name == "signReleaseBundle" })
}

flutter {
    source = "../.."
}
