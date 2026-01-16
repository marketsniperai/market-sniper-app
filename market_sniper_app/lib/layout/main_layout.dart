import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/textured_bar.dart'; // Textured UI
import '../screens/dashboard_screen.dart'; // Integration target

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Placeholder pages for tabs that don't exist yet
  final List<Widget> _pages = [
    // Index 0: Dashboard (Home)
    // We wrap it to ensure it fits the shell (we might need to refactor DashboardScreen to remove its internal Scaffold 
    // to strictly follow Canon, but for V1 we just place it here. 
    // If DashboardScreen has Scaffold, it nests. accepted for V1 speed.)
    const DashboardScreen(), 
    
    // Index 1: Watchlist
    const Center(child: Text("Watchlist (Coming Soon)")),
    
    // Index 2: News
    const Center(child: Text("News (Coming Soon)")),
    
    // Index 3: OnDemand
    const Center(child: Text("OnDemand (Coming Soon)")),
    
    // Index 4: Calendar
    const Center(child: Text("Calendar (Coming Soon)")),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showEliteOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.accentCyan, width: 1)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40, 
                    height: 4, 
                    color: AppColors.textDisabled, 
                    margin: const EdgeInsets.only(bottom: 20)
                  )
                ),
                Text(
                  "ELITE COMMAND", 
                  style: AppTypography.headline(context).copyWith(color: AppColors.accentCyan),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // TODO: 30% context visible behind overlay (managed by initialChildSize 0.7)
                Text(
                  "System Override Controls ... [PLACEHOLDER]",
                  style: AppTypography.body(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      
      // --- Always-on AppBar ---
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Allow texture to show
        elevation: 0,
        flexibleSpace: const TexturedBarBackground(
             child: SafeArea(child: SizedBox.expand()),
        ),
        leading: const Icon(Icons.menu, color: AppColors.textPrimary), // Menu Placeholder
        centerTitle: true,
        title: Text(
          "Market Sniper AI",
          style: AppTypography.logo(context, AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye, color: AppColors.textSecondary), // Elite Placeholder
            onPressed: _showEliteOverlay,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderSubtle, height: 1.0),
        ),
      ),

      // --- Body ---
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              // Top Pills / Status Bar Placeholder
              Container(
                height: 40,
                color: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text("LIVE", style: AppTypography.label(context).copyWith(color: AppColors.stateLive)),
                    const Spacer(),
                    Text("v1.0.0", style: AppTypography.caption(context)),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
        ],
      ),

      // --- Always-on Bottom Nav ---
      bottomNavigationBar: const TexturedBarBackground(
        child: _BottomNavContent(),
      ),
    );
  }
}

class _BottomNavContent extends StatelessWidget {
  const _BottomNavContent();

  @override
  Widget build(BuildContext context) {
    // Finding the parent state is a bit tricky if extracted, but for V1 let's keep it simple.
    // Actually, accessing _currentIndex and _onTabTapped requires callback or passing params.
    // Let's just inline it correctly to avoid refactoring state management right now.
    final state = context.findAncestorStateOfType<_MainLayoutState>();
    
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surface1.withOpacity(0.6))),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accentCyan,
        unselectedItemColor: AppColors.textDisabled,
        // We need to access state. logic below assumes state is accessible. 
        // Since we are inside MainLayout, valid context lookup is messy.
        // Let's NOT extract widget yet. Just fix the inline code.
        currentIndex: state?._currentIndex ?? 0,
        onTap: state?._onTabTapped,
        items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Watch'),
            BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
            BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Alpha'), // OnDemand
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Cal'),
        ],
      ),
    );
  }
}
