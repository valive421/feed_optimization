import 'package:flutter/material.dart';

import '../screens/feed_screen.dart';
import 'app_keys.dart';

class HighPerformanceFeedApp extends StatelessWidget {
  const HighPerformanceFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'High Performance Feed',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B998B)),
        useMaterial3: true,
      ),
      home: const FeedScreen(),
    );
  }
}
