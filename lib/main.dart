import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme_notifier.dart';
import 'providers/saved_verses_provider.dart';
import 'providers/verse_tracker_provider.dart';
import 'providers/translations_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => SavedVersesProvider()),
        ChangeNotifierProvider(create: (_) => VerseTrackerProvider()),
        ChangeNotifierProvider(create: (_) => TranslationsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _fallbackSeedColor = Colors.indigo;

  ThemeData _themeFromScheme(ColorScheme scheme, {bool isAmoled = false}) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isAmoled
          ? Colors.black
          : isDark
          ? const Color(0xFF121212)
          : null,
      canvasColor: isAmoled ? Colors.black : null,
      cardColor: isAmoled ? const Color(0xFF1A1A1A) : null,
      appBarTheme: AppBarTheme(
        backgroundColor: isAmoled ? Colors.black : scheme.surface,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: isAmoled ? Colors.white : scheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme =
            lightDynamic ??
            ColorScheme.fromSeed(
              seedColor: _fallbackSeedColor,
              brightness: Brightness.light,
            );

        final darkScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: _fallbackSeedColor,
              brightness: Brightness.dark,
            );

        return MaterialApp(
          title: 'Dhammapada',
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.themeMode,
          theme: _themeFromScheme(lightScheme),
          darkTheme: themeNotifier.isAmoled
              ? _themeFromScheme(darkScheme, isAmoled: true)
              : _themeFromScheme(darkScheme),
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
