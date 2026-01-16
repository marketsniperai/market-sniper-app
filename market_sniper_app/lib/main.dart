import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Add import
import 'layout/main_layout.dart';
import 'theme/app_colors.dart';

void main() {
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
      home: const MainLayout(),
    );
  }
}
