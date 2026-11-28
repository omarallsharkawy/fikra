# Flutter embedding and app entrypoints
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.fikra.app.** { *; }
-dontwarn com.google.android.play.core.**

# Keep JNI native methods and classes invoked from native code
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# flutter_secure_storage & Google Tink
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# record / just_audio / Media3
-keep class com.llfbandit.record.** { *; }
-keep class com.ryanheise.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Legacy demo plugins (ffmpeg_kit_flutter_new_min)
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**
-dontwarn javax.annotation.**
