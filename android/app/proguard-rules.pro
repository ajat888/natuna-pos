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

# Jangan sentuh komponen SharedPreferences & Kotlin
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class com.google.common.reflect.TypeToken { *; }
-keep class * extends com.google.common.reflect.TypeToken { *; }