-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
# Keep TensorFlow Lite GPU delegate classes
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Keep TensorFlow GPU delegate factory and options
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Sometimes needed if reflection is used
-keepclassmembers class * {
    @org.tensorflow.lite.support.annotation.* <fields>;
    @org.tensorflow.lite.support.annotation.* <methods>;
}

# Optional (to prevent stripping metadata)
-keepattributes *Annotation*
