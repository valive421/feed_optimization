import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/feed_screen.dart';
import 'app_keys.dart';

class HighPerformanceFeedApp extends StatelessWidget {
  const HighPerformanceFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'High Performance Feed',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8F6F1),
        textTheme: GoogleFonts.soraTextTheme().apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF8F6F1),
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        useMaterial3: true,
      ),
      home: const FeedScreen(),
    );
  }
}
