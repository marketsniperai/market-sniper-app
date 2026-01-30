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
  
  // D49: Elite Overlay State
  bool _isEliteOpen = false;
  String? _eliteExplainKey;
  Map<String, dynamic>? _elitePayload;
  bool _eliteResetToWelcome = false;

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

  void _toggleEliteOverlay() {
    setState(() {
      _isEliteOpen = !_isEliteOpen;
      if (_isEliteOpen) {
        // Default open state
        _eliteExplainKey = null;
        _elitePayload = null;
        _eliteResetToWelcome = false;
      }
    });
  }

  void _openEliteExplain({String? explainKey, Map<String, dynamic>? payload, bool resetToWelcome = false}) {
    setState(() {
      _isEliteOpen = true;
      _eliteExplainKey = explainKey;
      _elitePayload = payload;
      _eliteResetToWelcome = resetToWelcome;
    });
  }

  void _closeElite() {
    setState(() {
      _isEliteOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // D49.ELITE.FIX.02: Intercept Back Button
    return PopScope(
      canPop: !_isEliteOpen, // Only allow pop if Elite is closed
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If we are here, Elite is Open and we blocked pop.
        _closeElite();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        // D45.05 Premium Menu
        // drawer: Drawer(...), // REMOVED per Polish (Replaced by MenuScreen)
        body: NotificationListener<EliteExplainNotification>(
          onNotification: (notification) {
            _openEliteExplain(
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
                                // D49: Elite Toggle
                                IconButton(
                                  icon: Icon(Icons.shield,
                                      // Highlight if open
                                      color: _isEliteOpen ? AppColors.neonCyan : AppColors.textSecondary),
                                  onPressed: _toggleEliteOverlay,
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
                      // D49: Stack here? No, Elite Overlay is Global (above BottomNav too?)
                      // Prompt says: "Base: current tab content. Overlay: Elite panel (Positioned bottom = BottomNav height)"
                      // BottomNav lives in the column.
                      // If we want Elite ABOVE BottomNav, we need the Stack to wrap the *entire* Scaffold body structure, OR put Elite *outside* this Column.
                      // Let's look at the structure: SafeArea -> Column -> [TopBar, Expanded(Content), BottomNav].
                      // The previous `Stack` wrapped this entire `SafeArea`.
                      // So `Elite` should be a sibling of `SafeArea`.
                      // But `SafeArea` has the Top/Bottom bars.
                      // If we want Elite to cover Bottom Nav or check alignment...
                      // Requirements: "Elite panel lives as a bottom sheet-like console anchored above BottomNav."
                      // "Back button closes Elite panel only."
                      // Let's keep existing column structure for "App Content" and put Elite ABOVE it in the Stack.
                      // But we need to position Elite *above* the Bottom Nav.
                      // Bottom Nav height is roughly 56 + padding.
                      // Let's use `Stack` at root of `body`.
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

              // --- Elite Persistent Overlay ---
              if (_isEliteOpen)
                Positioned(
                   left: 0,
                   right: 0,
                   bottom: 60, // Anchored above BottomNav (approx 56 + extra)
                   // We want it to take up some height.
                   height: MediaQuery.of(context).size.height * 0.65, 
                   child: EliteInteractionSheet(
                      initialExplainKey: _eliteExplainKey,
                      initialPayload: _elitePayload,
                      resetToWelcome: _eliteResetToWelcome,
                      onClose: _closeElite,
                      // Scroll controller handled internally if not passed, or we can use DraggableSheet logic if we want resize
                      // For D49.FIX.02, fixed height overlay is accepted.
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
      ),
    );
  }
}
