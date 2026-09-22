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
