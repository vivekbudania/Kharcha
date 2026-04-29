# Flutter-specific ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep shared_preferences
-keep class androidx.datastore.** { *; }

# Keep google_fonts
-keep class com.google.fonts.** { *; }

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn sun.misc.**

# Play Store deferred components and missing classes
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**
