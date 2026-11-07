import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'shared/providers/watchlist_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WatchlistProvider()..loadWatchlist(),
      child: const CineScopeApp(),
    ),
  );
}

class CineScopeApp extends StatelessWidget {
  const CineScopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineScope',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
