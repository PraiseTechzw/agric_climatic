# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Supabase classes
-keep class io.supabase.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }

# Keep model classes
-keep class com.agricclimatic.zimbabwe.models.** { *; }

# Keep service classes
-keep class com.agricclimatic.zimbabwe.services.** { *; }

# Keep provider classes
-keep class com.agricclimatic.zimbabwe.providers.** { *; }

# Keep widget classes
-keep class com.agricclimatic.zimbabwe.widgets.** { *; }

# Keep screen classes
-keep class com.agricclimatic.zimbabwe.screens.** { *; }

# Keep notification classes
-keep class com.agricclimatic.zimbabwe.notifications.** { *; }

# Keep HTTP classes
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep JSON serialization
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R class
-keep class com.agricclimatic.zimbabwe.R$* {
    public static <fields>;
}

# Keep all classes in the main package
-keep class com.agricclimatic.zimbabwe.** { *; }
