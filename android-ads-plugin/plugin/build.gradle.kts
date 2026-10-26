// A small Godot Android plugin (v2) that shows kid-safe Google AdMob interstitials.
// Built by CI into godot/addons/jelly_ads/bin/jelly-ads-release.aar.
plugins {
    id("com.android.library")
}

android {
    namespace = "com.vedshubham.jellyads"
    compileSdk = 34
    defaultConfig {
        minSdk = 21
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    compileOnly("org.godotengine:godot:4.3.0.stable")
    // Godot adds this to the game too (see godot/addons/jelly_ads/plugin.gd); keep the versions in step.
    compileOnly("com.google.android.gms:play-services-ads:23.6.0")
}
