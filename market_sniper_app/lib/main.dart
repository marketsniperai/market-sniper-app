import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Add import
import 'layout/main_layout.dart';
import 'screens/war_room_screen.dart';
import 'theme/app_colors.dart';

import 'config/app_config.dart';
import 'guards/layout_police.dart';

void main() {
  LayoutPoliceGuard.install(enabled: AppConfig.isFounderBuild);
  runApp(const MarketSniperApp());
}

class MarketSniperApp extends StatelessWidget {
  const MarketSniperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketSniper Day 05',
      // Theme Integration (Canon V1)
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bgPrimary,
        primaryColor: AppColors.accentCyan,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme), // Apply premium typography
        colorScheme: const ColorScheme.dark().copyWith(
          primary: AppColors.accentCyan,
          secondary: AppColors.accentCyanDim,
          surface: AppColors.surface1,
        ),
      ),
      routes: {
        '/war_room': (context) => const WarRoomScreen(),
      },
      home: const MainLayout(),
    );
  }
}
