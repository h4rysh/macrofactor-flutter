import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Automatically populate google-services.json from template for CI or fresh checkouts
val googleServicesFile = file("google-services.json")
val googleServicesTemplate = file("google-services.json.example")
if (!googleServicesFile.exists() && googleServicesTemplate.exists()) {
    googleServicesTemplate.copyTo(googleServicesFile)
}

// Release keystore resolution from key.properties or environment variables
val keystoreProperties = Properties()
val rootKeyProps = rootProject.file("key.properties")
val appKeyProps = file("key.properties")
if (rootKeyProps.exists()) {
    keystoreProperties.load(FileInputStream(rootKeyProps))
} else if (appKeyProps.exists()) {
    keystoreProperties.load(FileInputStream(appKeyProps))
}

val releaseKeyAlias = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
val releaseStoreFilePath = keystoreProperties.getProperty("storeFile") ?: System.getenv("KEYSTORE_PATH")
val releaseStorePassword = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")

val hasReleaseSigning = !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank() &&
    !releaseStoreFilePath.isNullOrBlank() &&
    !releaseStorePassword.isNullOrBlank()

android {
    namespace = "com.h4rysh.sique"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    packaging {
        resources {
            excludes += "META-INF/version-control-info.textproto"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.h4rysh.sique"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                val resolvedStore = if (File(releaseStoreFilePath).isAbsolute) {
                    File(releaseStoreFilePath)
                } else if (rootProject.file(releaseStoreFilePath).exists()) {
                    rootProject.file(releaseStoreFilePath)
                } else {
                    file(releaseStoreFilePath)
                }
                storeFile = resolvedStore
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            if (!hasReleaseSigning) {
                // Do NOT fall back to debug signing.
                // Leave release signing unconfigured so attempting to build release without keys fails clearly.
            } else {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseTasks = listOf(":app:assembleRelease", ":app:bundleRelease", ":app:packageRelease")
    val hasReleaseTask = allTasks.any { task -> releaseTasks.any { task.path.contains(it) } }
    if (hasReleaseTask && !hasReleaseSigning) {
        throw GradleException(
            "Release build aborted: Release signing configuration not found. " +
            "Please configure key.properties or set environment variables (KEY_ALIAS, KEY_PASSWORD, KEYSTORE_PATH, KEYSTORE_PASSWORD). " +
            "Release builds cannot fall back to debug signing."
        )
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
