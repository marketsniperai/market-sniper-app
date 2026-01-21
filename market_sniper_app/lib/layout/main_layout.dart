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
import '../screens/share_attribution_dashboard_screen.dart' as import_target;


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  
  // D38.01 War Room Access (Legacy/Unified)
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

  // D45.13 Command Center Ritual State
  int _ccTapCount = 0;
  DateTime? _ccLastTapTime;

  void _onLogoTap() {
     _handleRitualTap();
  }

  void _onTitleTap() {
     // Legacy Founder Wrapper (if needed) or merged.
     // Let's forward to ritual handler to keep it clean.
     _handleRitualTap();
  }

  void _handleRitualTap() {
    final now = DateTime.now();
    
    // Reset if slow (> 1s gap)
    if (_ccLastTapTime != null && now.difference(_ccLastTapTime!) > const Duration(seconds: 1)) {
      _ccTapCount = 0;
    }
    
    _ccTapCount++;
    _ccLastTapTime = now;
    
    // Command Center: 4 Taps
    if (_ccTapCount == 4) {
       // Check Access (Elite or Founder)
       // We can lazily push, the screen handles gating visuals.
       // But to be hidden for Free/Guest, maybe check mostly? 
       // Policy: "free_access: HIDDEN".
       // We'll push, and the screen will show "NO SIGNAL" or similar if locked. 
       // Or better visuals: Shake?
       // Let's just push. Gating is in the screen.
       debugPrint("COMMAND_CENTER_RITUAL_TRIGGERED");
       Navigator.push(context, MaterialPageRoute(builder: (_) => const cc_screen.CommandCenterScreen()));
       return;
    }

    // War Room: 5 Taps (Founder Only)
    // If we hit 4, we triggered CC. If user continues tapping to 5...
    // The previous push might have happened? 
    // If synchronous, yes.
    // If we want both, we need a delay at 4?
    // "Separation rule: War Room = Founder-only ... Command Center = Elite-only"
    // Since War Room is strictly Founder, and Founder sees CC labeled, 
    // maybe 4 taps opens CC for everyone (who is Elite).
    // Founders might be annoyed if CC opens when they want War Room.
    // Compromise: Founders use 5 taps. Elites use 4.
    // If Founder, at 4 taps, Wait?
    // Complexity.
    // Simpler: 4 Taps = Command Center. 
    // Founder War Room Access via 5 taps is legacy. 
    // Let's preserve Founder War Room logic but maybe move it or require a long press?
    // Or just let it collision. If CC opens, Founder can back out.
    // OR: Use the existing logic for War Room (checking AppConfig.isFounderBuild).
    
    // UPDATED LOGIC:
    // If Founder -> 5 Taps = War Room. (Swallow 4?)
    // If Non-Founder Elite -> 4 Taps = CC.
    
    if (AppConfig.isFounderBuild) {
       // Founder Mode
       if (_ccTapCount >= 5) {
          _ccTapCount = 0; // Reset
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomScreen()));
       }
       // Do not trigger at 4 for Founder to avoid modal overlap (or just accept it).
       // Actually, I'll let Founder trigger CC at 4. If they keep tapping, they get War Room on top?
       // No, simpler to just trigger War Room at 5. 
    } else {
       // Non-Founder (Elite/Others)
       if (_ccTapCount == 4) {
          _ccTapCount = 0;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const cc_screen.CommandCenterScreen()));
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
              if (AppConfig.isFounderBuild)
                 ListTile(
                   leading: const Icon(Icons.analytics, color: AppColors.accentCyan),
                   title: Text("Share Attribution (Founder)", style: AppTypography.label(context)),
                   onTap: () {
                     Navigator.pop(context);
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const import_target.ShareAttributionDashboardScreen()));
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
                                // D45.13 Command Center Ritual (Logo Tap)
                                onDoubleTap: () {}, // consume
                                onLongPress: () {}, // consume
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: GestureDetector(
                                    onTap: _onLogoTap, // Separate from Title Tap (Founder) or unified? 
                                    // Prompt says: "Tap 4x to open Command Center... pointing to top bar logo/title"
                                    // _onTitleTap is currently Founder War Room (5 taps).
                                    // Let's use _onLogoTap for Command Center (4 taps).
                                    // Wait, if _onTitleTap is on the Text, I should combine or separate.
                                    // "Ritual: TAP_LOGO_4X_WITHIN_4S"
                                    // Current _onTitleTap is on the TEXT "Market Sniper AI".
                                    // War Room = Founder. Command Center = Elite.
                                    // If Founder taps 5 times, they get War Room.
                                    // If Elite taps 4 times, they get Command Center.
                                    // Founder is also Elite.
                                    // If I tap 4 times, I trigger Command Center.
                                    // If I tap 5 times, I trigger War Room (if Founder).
                                    // Logic collision?
                                    // If I tap 5 times rapidly, I hit 4 first.
                                    // Logic: On 4th tap, wait slightly? Or simpler:
                                    // Different targets?
                                    // Prompt: "via a tap ritual on the top bar title/logo".
                                    // "Access ritual: 'Tap 4× to open Command Center' bubble pointing to top bar logo/title."
                                    // "Separation rule: War Room = Founder-only ... Command Center = Elite-only"
                                    // I will use `_onLogoTap` attached to the Text, and split logic inside.
                                    // Or clearer: 4 taps = CC. 5+ taps = War Room (Founder Override).
                                    // Actually, let's keep _onTitleTap which is already there, and enhance it.
                                    child: Text(
                                      "Market Sniper AI",
                                      style: AppTypography.logo(context, AppColors.textPrimary),
                                    ),
                                  ),
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

