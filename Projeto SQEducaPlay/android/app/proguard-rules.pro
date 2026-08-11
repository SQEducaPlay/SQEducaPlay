# Regras de otimização para Flutter/Android
# Mantém classes do embedding e plugins do Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Mantém Activities e Providers gerados do projeto
-keep class br.com.sqeducaplay.sqeducaplay.** { *; }

# Mantém classes anotadas por Keep (caso bibliotecas usem)
-keep @androidx.annotation.Keep class * { *; }
-keep class * { @androidx.annotation.Keep *; }

# SQFlite/Audioplayers/Path Provider/Flutter TTS normalmente não exigem regras específicas,
# mas preservamos nomes públicos para segurança mínima
-keep class com.tekartik.sqflite.** { *; }
-keep class xyz.luan.audioplayers.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class com.tundralabs.fluttertts.** { *; }

# Suprimir warnings conhecidos não críticos
-dontwarn java.awt.**
-dontwarn javax.**
