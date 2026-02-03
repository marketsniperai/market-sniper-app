import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repositories/war_room_repository.dart';
import '../models/war_room_snapshot.dart';
import '../models/system_health_snapshot.dart';
import '../services/api_client.dart';

import '../logic/war_room_refresh_controller.dart';
import '../config/app_config.dart';

// D53 Zones
import '../widgets/war_room/zones/global_command_bar.dart';
import '../widgets/war_room/zones/service_honeycomb.dart';
import '../widgets/war_room/zones/alpha_strip.dart';
import '../widgets/war_room/zones/console_gates.dart';

class WarRoomScreen extends StatefulWidget {
  const WarRoomScreen({super.key});

  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen>
    with WidgetsBindingObserver {
  late WarRoomRepository _repo;
  late WarRoomRefreshController _refreshController;

  WarRoomSnapshot _snapshot = WarRoomSnapshot.initial;
  bool _loading = true; // Initial load spinner
  bool _silentRefreshing = false; // For subtle indicator
  String? _errorMessage; // D53.3D: Compact Error State
  bool _showSources = false; // D53.6B: Truth Sources Overlay

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = WarRoomRepository(api: ApiClient());

    _refreshController = WarRoomRefreshController(onRefresh: _handleRefresh);

    // Initial Load
    _loadData(); // This handles the first spinner

    // Start Governance (will schedule next)
    _refreshController.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _refreshController.pause();
    } else if (state == AppLifecycleState.resumed) {
      _refreshController.resume();
    }
  }

  // Initial heavy load (spinner)
  Future<void> _loadData() async {
    await _handleRefresh(initial: true);
  }

  // The core refresh logic callback
  Future<void> _handleRefresh({bool initial = false}) async {
    if (initial) {
      setState(() => _loading = true);
    } else {
      setState(() => _silentRefreshing = true);
    }

    try {
      final data = await _repo.fetchSnapshot();

      // Governance Check
      bool backoff = false;
      // OS Health Locked?
      if (data.osHealth.status == HealthStatus.locked) backoff = true;
      // Any tile unavailable?
      if (!data.autopilot.isAvailable ||
          !data.misfire.isAvailable ||
          !data.housekeeper.isAvailable ||
          !data.iron.isAvailable ||
          !data.universe.isAvailable) {
        backoff = true;
      }

      _refreshController.reportEffectiveState(backoff);

      if (mounted) {
        setState(() {
          _snapshot = data;
          _loading = false;
          _silentRefreshing = false;
          _errorMessage = null; // Clear error on success
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _silentRefreshing = false;
          _errorMessage = "WAR ROOM DATA: ${e.toString().replaceAll('Exception:', '').trim()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("WARROOM_BUILD_ENTER: Width=${MediaQuery.of(context).size.width}");

    // Add post-frame callback for attach verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("WARROOM_SCROLL_ATTACH");
    });

    // D53.3D: Prefer Server Timestamp (Proof of Life) -> Local Refresh Time
    final serverTime = DateTime.tryParse(_snapshot.universe.timestampUtc);
    final displayTime = serverTime ?? _refreshController.lastRefreshTime;

    final width = MediaQuery.of(context).size.width;
    // D53.6C Responsive Breakpoints
    int z2Cols = width < 520 ? 2 : width < 820 ? 3 : width < 1200 ? 4 : 6;
    int z3Cols = width < 520 ? 2 : width < 820 ? 2 : width < 1200 ? 4 : 4; // Tighter for Alpha
    
    debugPrint("WARROOM_LAYOUT w=$width z2_cols=$z2Cols z3_cols=$z3Cols loading=$_loading err=${_errorMessage != null}");

    final body = RefreshIndicator(
        onRefresh: () async => await _refreshController.requestManualRefresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: Container(color: Colors.green, padding: EdgeInsets.all(4), child: Text("WARROOM_MARKER_TOP", style: TextStyle(color: Colors.black)))),

            // Spacer
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // D53.3D: Compact Error Banner (Neutral)
            if (_errorMessage != null)
              SliverToBoxAdapter(
                  child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.surface2,
                    border: Border.all(color: AppColors.borderSubtle),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(children: [
                   Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                   const SizedBox(width: 8),
                   Expanded(child: Text(_errorMessage!, style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.textSecondary))),
                ]),
              )),

            // Zone 2: Service Honeycomb (Infrastructure)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              sliver: ServiceHoneycomb(
                snapshot: _snapshot,
                loading: _loading,
                showSources: _showSources,
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 8)), // Gap
            
            // Zone 3: Alpha Strip (Intelligence)
            // AlphaStrip is implemented as a SliverPadding wrapping a SliverGrid
            AlphaStrip(
              snapshot: _snapshot,
              loading: _loading,
              showSources: _showSources,
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 8)), // Gap

            // Zone 4: Console / Gates
            ConsoleGates(
              snapshot: _snapshot,
              loading: _loading,
              founderTruthOverlay: AppConfig.isFounderBuild ? _buildFounderTruthContent() : null,
            ),
            
            SliverToBoxAdapter(child: Container(color: Colors.red, padding: EdgeInsets.all(4), child: Text("WARROOM_MARKER_BOTTOM", style: TextStyle(color: Colors.white)))),
            const SliverToBoxAdapter(child: SizedBox(height: 32)), // Bottom padding
          ],
        ),
      );

    debugPrint("WARROOM_BUILD_EXIT");

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // Zone 1: Global CommandBar (Fixed Top)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(42), // Founder Dense
        child: SafeArea(
          child: GlobalCommandBar(
            snapshot: _snapshot,
            onRefresh: () => _refreshController.requestManualRefresh(),
            loading: _loading,
            silentRefreshing: _silentRefreshing,
            lastRefreshTime: displayTime,
            showSources: _showSources,
            onToggleSources: () => setState(() => _showSources = !_showSources),
          ),
        ),
      ),
      body: body,
    );
  }

  // Helper for Founder Truth (passed to Zone 4)
  Widget _buildFounderTruthContent() {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          title: Text(
            "FOUNDER TRUTH SURFACE",
            style: AppTypography.caption(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _truthRow("OS Health", _snapshot.osHealth.status.toString(),
                      "unified"),
                  _truthRow("Misfire", _snapshot.misfire.source,
                      _snapshot.misfire.isAvailable ? "OK" : "MISSING"),
                  _truthRow("Iron OS", _snapshot.iron.source,
                      _snapshot.iron.isAvailable ? "OK" : "MISSING"),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _truthRow(String label, String value, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption(context)),
          Expanded(
            child: Text(
              "$value ($status)",
              style: AppTypography.caption(context).copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: GoogleFonts.robotoMono().fontFamily,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
