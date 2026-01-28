import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/textured_bar.dart'; // Textured UI
import '../screens/dashboard_screen.dart'; // Integration target
import '../screens/watchlist_screen.dart'; // D39.01 Integration
// D42 War Room Entry Fix
import '../screens/on_demand_panel.dart'; // D44.04B Hygiene
// import '../screens/universe/universe_screen.dart';
import '../config/app_config.dart';
import '../widgets/elite_interaction_sheet.dart';
import '../logic/elite_messages.dart';
import '../logic/navigation_bus.dart'; // D44.02B Integration
import '../logic/tab_state_store.dart'; // D45.02 Persistence
import '../screens/news_screen.dart'; // D45.03 News Tab
import '../screens/calendar_screen.dart'; // D45.04 Calendar Tab
// D45.05 Premium Screen
import '../logic/trial_engine.dart'; // D45.06 Trial Engine
import '../logic/plus_unlock_engine.dart'; // D45.14
// D45.17
import '../screens/command_center_screen.dart' as cc_screen; // D45.13/15
import 'dart:async'; // StreamSubscription
import '../screens/menu_screen.dart'; // D46 Polish
import '../widgets/founder/founder_router_sheet.dart' as founder_sheet;

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  Widget? _activeOverlay; // D45: Generic Shell Overlay (Menu, Account, etc.)

  void _setOverlay(Widget? overlay) {
    setState(() => _activeOverlay = overlay);
  }

  // D38.01 War Room Access (Legacy/Unified)
  StreamSubscription<NavigationEvent>? _navSubscription;
  final _tabStore = TabStateStore();

  @override
  void initState() {
    super.initState();
    _restoreLastTab(); // D45.02 Restore State

    // D45.06 Trial Engine Check
    TrialEngine.checkAndIncrement(); // Fire and forget (it is async/safe)

    // D45.14 Plus Unlock Check
    PlusUnlockEngine.checkAndIncrement();

    // D44.02B / D45.02 Intent Priority: Intent wins over restore if simultaneous (by nature of Stream)
    // Also persist intent-driven changes.
    _navSubscription = NavigationBus().events.listen((event) {
      if (mounted) {
        setState(() => _currentIndex = event.tabIndex);
        _tabStore.saveLastTabIndex(event.tabIndex);
      }
    });
  }

  Future<void> _restoreLastTab() async {
    final lastIndex = await _tabStore.loadLastTabIndex();
    if (mounted) {
      // Only restore if we haven't already moved (e.g. by fast intent)
      // But practically, on cold boot, this runs first.
      setState(() {
        _currentIndex = lastIndex;
      });
    }
  }

  @override
  void dispose() {
    _navSubscription?.cancel();
    super.dispose();
  }

  // D45.13 Command Center Ritual State
  int _ccTapCount = 0;
  DateTime? _ccLastTapTime;

  // D45 Founder Router
  bool _isFounderSheetOpen = false;

  void _handleRitualTap() {
    final now = DateTime.now();
    final isFounderBuild = AppConfig.isFounderBuild;

    // Reset if slow (> 2s gap to be more forgiving)
    if (_ccLastTapTime != null &&
        now.difference(_ccLastTapTime!) > const Duration(seconds: 2)) {
      _ccTapCount = 0;
    }

    _ccTapCount++;
    _ccLastTapTime = now;

    // D45 Founder Router Selector Logic
    debugPrint("RITUAL: tap $_ccTapCount (isFounder=$isFounderBuild)");

    if (isFounderBuild) {
      // Founder: 4 or 5 taps opens the Selector
      if (_ccTapCount >= 4 && !_isFounderSheetOpen) {
        debugPrint("FOUNDER_RITUAL_TRIGGERED taps=$_ccTapCount");
        _ccTapCount = 0; // Reset
        _isFounderSheetOpen = true;

        showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const founder_sheet.FounderRouterSheet()).then((_) {
          _isFounderSheetOpen = false; // Reset lock on close
        });
        return;
      }
    } else {
      // Non-Founder (Elite/Others): Only 4 taps -> C.C.
      if (_ccTapCount == 4) {
        _ccTapCount = 0;
        _setOverlay(
            cc_screen.CommandCenterScreen(onBack: () => _setOverlay(null)));
      }
    }
  }

  // Placeholder pages for tabs
  final List<Widget> _pages = [
    // Index 0: Home (Dashboard)
    const DashboardScreen(),

    // Index 1: Watchlist
    const WatchlistScreen(),

    // Index 2: News
    const NewsScreen(),

    // Index 3: OnDemand
    const OnDemandPanel(),

    // Index 4: Calendar
    const CalendarScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar(); // D46 Polish: Clear snacks on nav
    }
    setState(() {
      _currentIndex = index;
      _activeOverlay = null; // Close any overlay on nav
    });
    _tabStore.saveLastTabIndex(index);
  }

  void _showEliteOverlay(
      {String? explainKey,
      Map<String, dynamic>? payload,
      bool resetToWelcome = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return EliteInteractionSheet(
              initialExplainKey: explainKey,
              initialPayload: payload,
              resetToWelcome: resetToWelcome,
              scrollController: scrollController);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // D45.05 Premium Menu
      // drawer: Drawer(...), // REMOVED per Polish (Replaced by MenuScreen)
      body: NotificationListener<EliteExplainNotification>(
        onNotification: (notification) {
          _showEliteOverlay(
              explainKey: notification.explainKey,
              payload: notification.payload);
          return true;
        },
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // --- Top Bar (Custom) ---
                  TexturedBarBackground(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Replace Placeholder with Real Menu Trigger (opens Scaffold Drawer)
                              Builder(
                                builder: (context) => IconButton(
                                  // Toggle Menu via Overlay System
                                  icon: Icon(
                                      _activeOverlay != null
                                          ? Icons.close
                                          : Icons.menu,
                                      color: AppColors.textPrimary),
                                  onPressed: () {
                                    if (_activeOverlay != null) {
                                      _setOverlay(null);
                                    } else {
                                      _setOverlay(MenuScreen(
                                        onClose: () => _setOverlay(null),
                                        onNavigate: (widget) =>
                                            _setOverlay(widget),
                                      ));
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              // D45.H3: FIXED RITUAL HITBOX
                              // Removed nested GestureDetector. Ensured specific height/padding.
                              GestureDetector(
                                onTap: _handleRitualTap,
                                // D45: Removed onDoubleTap/onLongPress to allow rapid tapping for ritual
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  // Min Height 48px for reliability logic
                                  constraints: const BoxConstraints(
                                      minHeight: 48, minWidth: 120),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Text(
                                    "Market Sniper AI",
                                    style: AppTypography.logo(
                                        context, AppColors.textPrimary),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.shield,
                                    color: AppColors.textSecondary),
                                onPressed: () => _showEliteOverlay(
                                    explainKey: null, resetToWelcome: true),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        Container(color: AppColors.borderSubtle, height: 1.0),
                      ],
                    ),
                  ),

                  // D45.17 Session Awareness Micro-Panel
                  // Placed below Top Bar, above Content
                  // SessionAwarenessPanel removed per Polish (redundant with Dashboard Strip)

                  // --- Main Content (Expanded) ---
                  Expanded(
                    // Conditional Rendering: Menu vs Tabs
                    child: _activeOverlay != null
                        // HOTFIX.MENU.SHELL.03: Self-Heal Material Ancestor
                        ? Material(
                            type: MaterialType.transparency,
                            child: _activeOverlay,
                          )
                        : IndexedStack(
                            index: _currentIndex,
                            children: _pages,
                          ),
                  ),

                  // --- Bottom Nav (Custom) ---
                  TexturedBarBackground(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                color:
                                    AppColors.surface1.withValues(alpha: 0.6))),
                      ),
                      child: BottomNavigationBar(
                        backgroundColor: AppColors.transparent,
                        elevation: 0,
                        type: BottomNavigationBarType.fixed,
                        selectedItemColor: AppColors.neonCyan,
                        unselectedItemColor: AppColors.textDisabled,
                        selectedLabelStyle: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(fontSize: 10),
                        currentIndex: _currentIndex,
                        onTap: _onTabTapped,
                        items: const [
                          BottomNavigationBarItem(
                              icon: Icon(Icons.dashboard), label: 'Home'),
                          BottomNavigationBarItem(
                              icon: Icon(Icons.list), label: 'Watchlist'),
                          BottomNavigationBarItem(
                              icon: Icon(Icons.article), label: 'News'),
                          BottomNavigationBarItem(
                              icon: Icon(Icons.flash_on), label: 'On-Demand'),
                          BottomNavigationBarItem(
                              icon: Icon(Icons.calendar_today),
                              label: 'Calendar'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Shell Proof Overlay (Founder Only) ---
            if (AppConfig.isFounderBuild)
              Positioned(
                bottom: 60, // Above bottom nav
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: AppColors.bgPrimary.withValues(alpha: 0.8),
                  child: Text(
                    "SHELL OK | tab=$_currentIndex | child=${_pages[_currentIndex].runtimeType}",
                    style: const TextStyle(
                        color: AppColors.stateLive,
                        fontSize: 10,
                        fontFamily: 'RobotoMono',
                        decoration: TextDecoration.none),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
