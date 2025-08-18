# Camera X Rules
-keep class androidx.camera.** { *; }
-keep interface androidx.camera.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter QR Code Scanner
-keep class io.flutter.plugins.** { *; }
 ## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication

## Flutter WebRTC
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.** { *; } 


# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Keep TensorFlow Lite Select TF Ops classes
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep tflite_flutter plugin classes
-keep class io.flutter.plugins.tflite.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}