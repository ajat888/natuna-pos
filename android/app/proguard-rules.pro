# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep classes that use reflection (untuk plugin)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Aturan tambahan agar R8 tidak menghapus class Google Play
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }