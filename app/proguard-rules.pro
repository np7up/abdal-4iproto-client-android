# **********************************************************************
# -------------------------------------------------------------------
# Project Name : Abdal 4iProto Android
# File Name : proguard-rules.pro
# Author : Ebrahim Shafiei (EbraSha)
# Email : Prof.Shafiei@Gmail.com
# Created On : 2026-06-04 19:37:00
# Description : R8/ProGuard keep rules that preserve the reflection- and JNI-based components
#               (JSch, Bouncy Castle, native tunnel bridge, Room, kotlinx.serialization) so that
#               release builds with minification still establish the SSH tunnel correctly.
# -------------------------------------------------------------------
#
# "Coding is an engaging and beloved hobby for me. I passionately and insatiably pursue knowledge in cybersecurity and programming."
# – Ebrahim Shafiei
#
# **********************************************************************

# Keep metadata required by reflection-heavy libraries (generics, annotations, inner classes).
-keepattributes Signature,InnerClasses,EnclosingMethod,Exceptions
-keepattributes *Annotation*,AnnotationDefault
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations

# Keep readable crash stack traces in release builds (line numbers), but hide the real source file name.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile


# -------------------------------------------------------------------
# JNI bridge for the prebuilt libhev-socks5-tunnel native library.
# The native code registers methods against this exact class/method names,
# so neither the class nor its native methods may be renamed or removed.
# -------------------------------------------------------------------
-keep class hev.sockstun.TProxyService { *; }

# Preserve the name of any native method and its declaring class (JNI safety).
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# -------------------------------------------------------------------
# JSch (mwiede fork). Algorithm implementations (kex, ciphers, MACs, host keys,
# ssh-ed25519 signatures, compression) are loaded by fully-qualified class NAME
# via Class.forName from configuration strings. They must all be kept.
# -------------------------------------------------------------------
-keep class com.jcraft.jsch.** { *; }
-dontwarn com.jcraft.jsch.**

# -------------------------------------------------------------------
# Bouncy Castle is invoked reflectively by com.jcraft.jsch.bc.* for EdDSA/curve25519.
# -------------------------------------------------------------------
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# -------------------------------------------------------------------
# Room: keep entities and generated database/DAO implementations.
# -------------------------------------------------------------------
-keep class com.example.data.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keepclassmembers class * { @androidx.room.* <methods>; }
-dontwarn androidx.room.paging.**

# -------------------------------------------------------------------
# kotlinx.serialization: keep generated serializers for @Serializable classes.
# -------------------------------------------------------------------
-keepattributes RuntimeVisibleAnnotations
-keep,includedescriptorclasses class **$$serializer { *; }
-keepclassmembers class * {
    *** Companion;
}
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}
-dontwarn kotlinx.serialization.**

# -------------------------------------------------------------------
# Networking libraries present on the classpath (currently unused in code).
# Suppress missing-class warnings only; no keep needed.
# -------------------------------------------------------------------
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-dontwarn com.squareup.moshi.**
-dontwarn javax.annotation.**

# Coroutines internal field used by the debugger; harmless to keep quiet about.
-dontwarn kotlinx.coroutines.**
