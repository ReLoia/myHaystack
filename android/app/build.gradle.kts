import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "it.reloia.myhaystack"
    // TODO: remove this fix when flutter updates the compileSdkVersion to A17 (this is a fix for flutter_secure_storage)
    compileSdk = maxOf(37, flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "it.reloia.myhaystack"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasEnv =
                System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
            val keyPasswordEnv =
                System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")
            val storeFilePath =
                System.getenv("KEYSTORE_PATH") ?: keystoreProperties.getProperty("storeFile")
            val storePasswordEnv = System.getenv("KEYSTORE_PASSWORD")
                ?: keystoreProperties.getProperty("storePassword")

            if (!keyAliasEnv.isNullOrEmpty() && !keyPasswordEnv.isNullOrEmpty() && !storeFilePath.isNullOrEmpty() && !storePasswordEnv.isNullOrEmpty()) {
                keyAlias = keyAliasEnv
                keyPassword = keyPasswordEnv
                storeFile = file(storeFilePath)
                storePassword = storePasswordEnv
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.getByName("release")
            signingConfig =
                if (releaseConfig.storeFile != null) releaseConfig else signingConfigs.getByName("debug")

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
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
