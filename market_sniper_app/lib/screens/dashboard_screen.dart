import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Moved to Composer
// import '../theme/app_colors.dart'; // Moved to Composer
import '../models/dashboard_payload.dart';
import '../models/system_health.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';
// import '../widgets/dashboard_widgets.dart'; // Moved to Composer
import '../logic/data_state_resolver.dart';
import '../repositories/dashboard_repository.dart';
import '../utils/time_utils.dart';
// import '../widgets/session_window_strip.dart'; // Moved to Composer

// import '../widgets/system_health_chip.dart'; // Moved to Composer
// import '../widgets/os_health_widget.dart'; // Moved to Composer
// import '../widgets/last_run_widget.dart'; // Moved to Composer
// import '../widgets/founder_banner.dart'; // Moved to Composer
import '../logic/dashboard_refresh_controller.dart';
import '../repositories/system_health_repository.dart';
import '../repositories/last_run_repository.dart';
import '../models/system_health_snapshot.dart';
import '../models/last_run_snapshot.dart';
import '../logic/dashboard_degrade_policy.dart';
// import '../widgets/degrade_banner.dart'; // Moved to Composer
import 'dashboard/dashboard_composer.dart';
import '../ui/tokens/dashboard_spacing.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  late DashboardRepository _repo;
  late SystemHealthRepository _healthRepo;
  late LastRunRepository _lastRunRepo;
  late ApiClient _api; // Kept for health (separate concern for now, or move to repo later)
  DashboardPayload? _dashboard;
  SystemHealth? _health; // Legacy
  SystemHealthSnapshot _healthSnapshot = SystemHealthSnapshot.unknown;
  LastRunSnapshot _lastRunSnapshot = LastRunSnapshot.unknown;
  Map<String, dynamic>? _optionsContext; // D36.3
  
  bool _loading = true;
  String? _error;
  late DashboardRefreshController _refreshController;
  // Timer? _refreshTimer; // Replaced by DashboardRefreshController

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // D37.02: Initialize Timezones
    TimeUtils.init();

    _api = ApiClient();
    _repo = DashboardRepository(api: _api);
    _healthRepo = SystemHealthRepository(api: _api);
    _lastRunRepo = LastRunRepository(api: _api);

    _refreshController = DashboardRefreshController(
      onRefresh: () async => await _loadData(silent: true),
    );

    // Initial load
    _loadData().then((_) {
       // Start auto-refresh after initial load
       _refreshController.start();
    });
    
    // _startTimer(); // Removed
    
    // Forensic Trace
    if (AppConfig.isFounderBuild) {
      debugPrint("FOUNDER=true, keyInjected=true, baseUrl=${AppConfig.apiBaseUrl}");
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshController.resume();
      // Resume should trigger refresh if needed, handled by controller
    } else if (state == AppLifecycleState.paused) {
      _refreshController.pause();
    }
  }

  // Timer logic removed, handled by controller

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
       setState(() { _loading = true; _error = null; });
    }
    try {
      final results = await Future.wait([
        _repo.fetchDashboard(),
        _api.fetchSystemHealth(), // TODO: Move to SystemRepository
      ]);
      
      if (mounted) {
        setState(() {
          _dashboard = results[0] as DashboardPayload;
          _health = results[1] as SystemHealth; // Legacy
          
          // D37.04: Fetch Unified Health logic (integrated here for now to ensure data availability)
          // Ideally this should participate in the Future.wait, but we need _dashboard first for resolver override if possible.
          // However, repo.fetchUnifiedHealth accepts override.
          
          final d = _dashboard!;
          final resolved = DataStateResolver.resolve(dashboard: d, health: _health);
          
          // D37.07: Report Locked State to Controller
          _refreshController.reportLockedState(resolved.state == DataState.locked);
          
          // We trigger the unified fetch NOW, using the resolved state
          _healthRepo.fetchUnifiedHealth(dataState: resolved).then((h) {
             if (mounted) setState(() => _healthSnapshot = h);
          });

          // Fetch Last Run (D37.05)
          _lastRunRepo.fetchLastRun().then((lr) {
             if (mounted) setState(() => _lastRunSnapshot = lr);
          });
          
          // D36.3: Fetch Options Context (Async, non-blocking)
          _repo.fetchOptionsContext().then((opts) {
             if (mounted) {
               setState(() {
                 // We need to pass this to composer. 
                 // Storing in state for now, will add variable.
                 _optionsContext = opts;
               });
             }
          });

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          // Even on error, try to show whatever health we got if possible, 
          // but Future.wait fails all. 
          // For resilience, fetching health could be separate, but strict error handling is okay.
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // V1 Integration: No inner Scaffold. Inner AppBar content moved/suppressed.
    // Main shell handles the Scaffold/AppBar.
    
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshController.requestManualRefresh();
      },
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // D37.08: Degrade Policy
    final resolvedState = DataStateResolver.resolve(dashboard: _dashboard, health: _health);
    
    final degradeContext = DashboardDegradePolicy.evaluate(
      payload: _dashboard,
      dataState: resolvedState,
      fetchError: _error,
    );
    
    // -- Dashboard Composer (D38.01.1) --
    // Orchestrates the list of widgets
    final composer = DashboardComposer(
      dashboard: _dashboard,
      health: _health,
      healthSnapshot: _healthSnapshot,
      lastRunSnapshot: _lastRunSnapshot,
      isFounder: AppConfig.isFounderBuild,
      resolvedState: resolvedState,
      degradeContext: degradeContext,
      optionsContext: _optionsContext, // D36.3
    );

    final widgets = composer.buildList(context);

    if (_loading && _dashboard == null) {
       // Show loading indicator only if we have no data at all
       return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: DashboardSpacing.screenPadding,
      children: widgets,
    );
  }
}
