import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MarketSniperApp());
}

class MarketSniperApp extends StatelessWidget {
  const MarketSniperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketSniper Day 05',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const DashboardScreen(),
    );
  }
}
