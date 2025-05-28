import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme_notifier.dart';
import 'providers/bookmarks_provider.dart';
import 'providers/verse_tracker_provider.dart';
import 'providers/translations_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadPreferences();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
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

  ThemeData _themeFromScheme(
    ColorScheme scheme, {
    required bool isAmoled,
    required bool useSystemFont,
  }) {
    final isDark = scheme.brightness == Brightness.dark;

    final scaffoldColor = isAmoled
        ? Colors.black
        : isDark
        ? const Color(0xFF121212)
        : null;

    final font = useSystemFont ? null : 'Atkinson Hyperlegible';

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldColor,
      canvasColor: isAmoled ? Colors.black : null,
      cardColor: isAmoled ? const Color(0xFF1A1A1A) : null,
      fontFamily: font,
      appBarTheme: AppBarTheme(
        backgroundColor: isAmoled ? Colors.black : scheme.surface,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 10),
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: isAmoled ? Colors.white : scheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
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

        final darkTheme = _themeFromScheme(
          darkScheme,
          isAmoled: themeNotifier.isAmoled,
          useSystemFont: themeNotifier.useSystemFont,
        );

        return MaterialApp(
          title: 'PocketDhamma',
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.themeMode,
          theme: _themeFromScheme(
            lightScheme,
            isAmoled: false,
            useSystemFont: themeNotifier.useSystemFont,
          ),
          darkTheme: darkTheme,
          initialRoute: '/',
          routes: {
            '/': (_) => const HomeScreen(),
            '/settings': (_) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
