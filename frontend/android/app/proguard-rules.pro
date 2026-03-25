# 告知 Android R8 混淆引擎：忽略 ML Kit 里我们为了节省体积而故意没装载的日、韩、繁体语种包所导致的 ClassNotFound 误报
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.chinese.**

# 保护 ML Kit 视觉核心类不被混淆器碾碎
-keep class com.google.mlkit.vision.text.** { *; }
