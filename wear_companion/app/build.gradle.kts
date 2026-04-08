plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.healthpilot.health_pilot"
    compileSdk = 34

    defaultConfig {
        // Must be identical to the phone app's applicationId so the
        // Wearable Data Layer pairs them automatically.
        applicationId = "com.healthpilot.health_pilot"
        minSdk = 30  // Wear OS 3 minimum
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-service:2.8.3")
    implementation("androidx.wear:wear:1.3.0")

    // Wearable Data Layer API — must match version used by phone side
    implementation("com.google.android.gms:play-services-wearable:18.1.0")

    // Health Services Client for real-time sensor readings on Wear OS
    implementation("androidx.health:health-services-client:1.1.0-alpha03")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.8.1")
}
