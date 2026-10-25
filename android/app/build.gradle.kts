import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties()
val releaseSigningFile = rootProject.file("key.properties")
if (releaseSigningFile.isFile) {
    releaseSigningFile.inputStream().use { releaseSigningProperties.load(it) }
}

fun signingValue(environmentName: String, propertyName: String): String? =
    providers.environmentVariable(environmentName).orNull
        ?.takeIf { it.isNotBlank() }
        ?: releaseSigningProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("CHESS_MASTER_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = signingValue("CHESS_MASTER_STORE_PASSWORD", "storePassword")
val releaseKeyAlias = signingValue("CHESS_MASTER_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = signingValue("CHESS_MASTER_KEY_PASSWORD", "keyPassword")
val releaseSigningConfigured = listOf(
    releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword,
).all { it != null }

// Debug builds remain usable without secrets; release packaging fails closed.
gradle.taskGraph.whenReady {
    val packagesRelease = allTasks.any {
        it.project == project && it.name in setOf(
            "assembleRelease", "bundleRelease", "packageRelease", "packageReleaseBundle",
        )
    }
    if (packagesRelease) {
        check(releaseSigningConfigured) {
            "Release signing is not configured. Supply all four CHESS_MASTER signing " +
                "environment variables or a protected android/key.properties file. " +
                "See docs/release/signing_and_provenance.md."
        }
        check(rootProject.file(releaseStoreFile!!).isFile) {
            "The configured release keystore is not a file. No signing secrets were logged."
        }
    }
}

android {
    namespace = "in.sanskar.chessmaster"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "in.sanskar.chessmaster"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
