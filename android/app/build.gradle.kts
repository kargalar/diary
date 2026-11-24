import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()
if (signingPropertiesFile.isFile) {
    signingPropertiesFile.inputStream().use { signingProperties.load(it) }
}

fun releaseSigningValue(environmentName: String, propertyName: String): String =
    providers.environmentVariable(environmentName).orNull?.takeIf { it.isNotBlank() }
        ?: signingProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }
        ?: error("Set $environmentName or $propertyName in android/key.properties for release signing")

android {
    namespace = "com.example.diary"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.diary"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePath = releaseSigningValue("KARGALAR_KEYSTORE_PATH", "storeFile")
            storeFile = if (providers.environmentVariable("KARGALAR_KEYSTORE_PATH").orNull.isNullOrBlank()) {
                rootProject.file(keystorePath)
            } else {
                file(keystorePath)
            }
            storePassword = releaseSigningValue("KARGALAR_KEYSTORE_PASSWORD", "storePassword")
            keyAlias = releaseSigningValue("KARGALAR_KEY_ALIAS", "keyAlias")
            keyPassword = releaseSigningValue("KARGALAR_KEY_PASSWORD", "keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
