# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive
-keep class * extends com.google.crypto.tink.shaded.protobuf.GeneratedMessageLite { *; }
-keepclassmembers class * extends hive.HiveObject { *; }

# Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Firebase Auth
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Google Play Core (referenced by Flutter embedding)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Suppress all other missing class warnings from R8
-ignorewarnings
