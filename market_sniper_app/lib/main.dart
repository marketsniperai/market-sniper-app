import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Add import
import 'package:provider/provider.dart'; // Provider
import 'layout/main_layout.dart';
import 'screens/war_room_screen.dart';
import 'screens/welcome_screen.dart'; // Welcome Screen
import 'state/locale_provider.dart'; // Locale Provider
import 'theme/app_colors.dart';

import 'config/app_config.dart';
import 'services/notification_service.dart'; // Polish
import 'services/human_mode_service.dart'; // Polish Human Mode
import 'guards/layout_police.dart';
import 'guards/startup_guard.dart'; // Integrity
import 'widgets/global_back_overlay.dart'; // Polish Overlay
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Synthetic (Broken)
// import 'package:timezone/data/latest.dart' as tz; // Removed for Web Config
import 'l10n/generated/app_localizations.dart'; // Non-Synthetic (Fixed)

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  LayoutPoliceGuard.install(enabled: AppConfig.isFounderBuild);

  // Polish.Notifications.01
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone Initialization (Dashboard Banner V1)
  // tz.initializeTimeZones(); // Removed for Web Compatibility (D45)

  try {
    NotificationService().setNavigatorKey(navigatorKey);
    NotificationService().init();
    HumanModeService().init(); // Polish Human Mode
    // Invite Integrity
    // We fire and forget init here so it's ready, but Guard also checks it.
  } catch (e) {
    debugPrint("Failed to init notifications: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MarketSniperApp(),
    ),
  );
}

class MarketSniperApp extends StatefulWidget {
  const MarketSniperApp({super.key});

  @override
  State<MarketSniperApp> createState() => _MarketSniperAppState();
}

class _MarketSniperAppState extends State<MarketSniperApp> {
  final _backOverlayObserver = GlobalBackOverlayObserver();

  @override
  Widget build(BuildContext context) {
    // Consume Locale
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'MarketSniper Day 05',
      navigatorKey: navigatorKey,
      navigatorObservers: [_backOverlayObserver], // Track navigation

      // Locale Config
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      builder: (context, child) {
        // Wrap app in overlay and listen to Human Mode for global rebuilds
        return ListenableBuilder(
            listenable: HumanModeService(),
            builder: (context, _) {
              return GlobalBackOverlay(
                observer: _backOverlayObserver,
                child: child ?? const SizedBox.shrink(),
              );
            });
      },
      // Theme Integration (Canon V1)
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bgPrimary,
        primaryColor: AppColors.neonCyan,
        textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme), // Apply premium typography
        colorScheme: const ColorScheme.dark().copyWith(
          primary: AppColors.neonCyan,
          secondary: AppColors.accentCyanDim,
          surface: AppColors.surface1,
        ),
      ),
      initialRoute: '/welcome', // Entry Point
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/startup': (context) =>
            const StartupGuard(child: MainLayout()), // Guarded Shell
        '/war_room': (context) => const WarRoomScreen(),
      },
    );
  }
}
