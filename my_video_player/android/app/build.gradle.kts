plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 这里的 namespace 必须和你的文件夹结构对应
    namespace = "com.example.my_video_player"
    
    // 【修改点】直接写死版本号，不使用 flutter.compileSdkVersion
    compileSdk = 34 
    ndkVersion = "25.1.8937393" // 这是一个常用的稳定 NDK 版本

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.my_video_player"
        
        // 【修改点】直接写死版本号
        minSdk = flutter.minSdkVersion       // 支持安卓 5.0 以上
        targetSdk = 34    // 适配最新的安卓系统
        
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // 使用调试签名打包，省去配置正式签名的麻烦
            signingConfig = signingConfigs.getByName("debug")
            
            // 开启混淆可以减小体积并增加反编译难度
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
