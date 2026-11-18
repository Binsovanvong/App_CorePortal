# Flutter Framework and Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Local Authentication (Biometrics)
-keep class io.flutter.plugins.localauth.** { *; }

# PointyCastle / Cryptographic algorithms
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# RootBeer (used by flutter_jailbreak_detection for root check)
-keep class com.scottyab.rootbeer.** { *; }
-dontwarn com.scottyab.rootbeer.**

# Google Play Core (Flutter Deferred Components)
-dontwarn com.google.android.play.core.**

# Strip android.util.Log calls in release builds to eliminate log leakage
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

# Obfuscate source file metadata
-renamesourcefileattribute SourceFile
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,SourceFile,LineNumberTable,*Annotation*,EnclosingMethod
