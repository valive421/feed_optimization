import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/feed_screen.dart';
import '../screens/devtools_screen.dart';
import '../providers/devtools_provider.dart';
import 'app_keys.dart';

class HighPerformanceFeedApp extends ConsumerWidget {
  const HighPerformanceFeedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devState = ref.watch(devToolsProvider);

    // Apply debug-only global flags from the DevTools toggles.
    if (kDebugMode) {
      debugRepaintRainbowEnabled = devState.repaintRainbow;
      debugPaintSizeEnabled = devState.showPaintSize;
      timeDilation = devState.timeDilationFactor;
    }

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'High Performance Feed',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      showPerformanceOverlay: devState.showPerformanceOverlay,
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
      home: Builder(
        builder: (context) {
          return Stack(
            children: [
              const FeedScreen(),
              if (kDebugMode)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'devtoolsBtn',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DevToolsScreen())),
                    child: const Icon(Icons.developer_mode_rounded),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
