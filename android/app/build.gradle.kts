plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.socially_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 🔹 Notification plugin එකට අවශ්‍ය Desugaring මෙතනින් සක්‍රිය කරනවා
        isCoreLibraryDesugaringEnabled = true 
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.socially_app"
        minSdk = flutter.minSdkVersion // 🔹 Desugaring වැඩ කරන්න අවම 21 හෝ ඊට වැඩි විය යුතුයි
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 🔹 ලොකු dependencies තියෙන නිසා මේක true කරන්න
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 2.0.3 වෙනුවට මේ 2.1.4 version එක දාන්න
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
