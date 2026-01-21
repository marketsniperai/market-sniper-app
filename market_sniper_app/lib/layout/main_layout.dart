import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/textured_bar.dart'; // Textured UI
import '../screens/dashboard_screen.dart'; // Integration target
import '../screens/watchlist_screen.dart'; // D39.01 Integration
import '../screens/war_room_screen.dart'; // D42 War Room Entry Fix
import '../screens/on_demand_panel.dart'; // D44.04B Hygiene
// import '../screens/universe/universe_screen.dart';
import '../config/app_config.dart';
import '../widgets/elite_interaction_sheet.dart';
import '../logic/elite_messages.dart';
import '../logic/navigation_bus.dart'; // D44.02B Integration
import '../logic/tab_state_store.dart'; // D45.02 Persistence
import '../screens/news_screen.dart'; // D45.03 News Tab
import '../screens/calendar_screen.dart'; // D45.04 Calendar Tab
import '../screens/premium_screen.dart'; // D45.05 Premium Screen
import '../logic/trial_engine.dart'; // D45.06 Trial Engine
import 'dart:async'; // StreamSubscription

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  
  // D38.01 War Room Access
  int _tapCount = 0;
  DateTime? _lastTapTime;
  DateTime? _cooldownUntil;
  StreamSubscription<NavigationEvent>? _navSubscription;
  final _tabStore = TabStateStore();

  @override
  void initState() {
    super.initState();
    _restoreLastTab(); // D45.02 Restore State
    
    // D45.06 Trial Engine Check
    TrialEngine.checkAndIncrement(); // Fire and forget (it is async/safe)
    
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

  void _onTitleTap() {
    if (!AppConfig.isFounderBuild) return;

    final now = DateTime.now();
    // Cooldown check
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) return;

    // Reset if too slow (900ms window to keep tapping)
    if (_lastTapTime != null && now.difference(_lastTapTime!) > const Duration(milliseconds: 900)) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      _cooldownUntil = now.add(const Duration(seconds: 5)); // 5s cooldown to prevent double-nav
      
      debugPrint("WAR_ROOM_ENTRY_TRIGGERED");
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomScreen()));
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
    setState(() {
      _currentIndex = index;
    });
    _tabStore.saveLastTabIndex(index);
  }

  void _showEliteOverlay({String? explainKey, Map<String, dynamic>? payload, bool resetToWelcome = false}) {
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
             scrollController: scrollController
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // D45.05 Premium Menu
      drawer: Drawer(
        backgroundColor: AppColors.surface1,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.surface1,
                  border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Center(
                  child: Text(
                    "MARKET SNIPER", 
                    style: AppTypography.title(context).copyWith(letterSpacing: 2.0),
                  ),
                ),
              ),
              ListTile(
                 leading: const Icon(Icons.stars, color: AppColors.accentCyan),
                 title: Text("Premium Protocol", style: AppTypography.label(context)),
                 onTap: () {
                   Navigator.pop(context); // Close drawer
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                 },
              ),
              // Add other placeholders if needed or keep clean
            ],
          ),
        ),
      ),
      body: NotificationListener<EliteExplainNotification>(
        onNotification: (notification) {
          _showEliteOverlay(explainKey: notification.explainKey, payload: notification.payload);
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             // Replace Placeholder with Real Menu Trigger (opens Scaffold Drawer)
                             Builder(
                               builder: (context) => IconButton(
                                 icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                                 onPressed: () => Scaffold.of(context).openDrawer(),
                                 padding: EdgeInsets.zero,
                                 constraints: const BoxConstraints(),
                               ),
                             ),
                            GestureDetector(
                                onTap: _onTitleTap,
                                child: Text(
                                  "Market Sniper AI",
                                  style: AppTypography.logo(context, AppColors.textPrimary),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.shield, color: AppColors.textSecondary),
                              onPressed: () => _showEliteOverlay(explainKey: null, resetToWelcome: true),
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

                // --- Main Content (Expanded) ---
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _pages,
                  ),
                ),

                // --- Bottom Nav (Custom) ---
                TexturedBarBackground(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.surface1.withValues(alpha: 0.6))),
                    ),
                    child: BottomNavigationBar(
                      backgroundColor: AppColors.transparent,
                      elevation: 0,
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: AppColors.accentCyan,
                      unselectedItemColor: AppColors.textDisabled,
                      selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: const TextStyle(fontSize: 10),
                      currentIndex: _currentIndex,
                      onTap: _onTabTapped,
                      items: const [
                        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
                        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Watchlist'),
                        BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
                        BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'On-Demand'),
                        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: AppColors.bgPrimary.withValues(alpha: 0.8),
                child: Text(
                  "SHELL OK | tab=$_currentIndex | child=${_pages[_currentIndex].runtimeType}",
                  style: const TextStyle(color: AppColors.stateLive, fontSize: 10, fontFamily: 'RobotoMono', decoration: TextDecoration.none),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

