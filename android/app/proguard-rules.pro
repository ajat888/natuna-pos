# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep classes that use reflection (untuk plugin)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}