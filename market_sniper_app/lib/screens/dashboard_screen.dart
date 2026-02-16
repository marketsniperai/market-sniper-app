import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Moved to Composer
// import '../theme/app_colors.dart'; // Moved to Composer
import '../models/dashboard_payload.dart';
import '../models/system_health.dart';
// import '../services/api_client.dart'; // Removed (D74 Snapshot-First Law)
import '../config/app_config.dart';
// import '../widgets/dashboard_widgets.dart'; // Moved to Composer
import '../logic/data_state_resolver.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/unified_snapshot_repository.dart'; // D73
import '../utils/time_utils.dart';
// import '../widgets/session_window_strip.dart'; // Moved to Composer

// import '../widgets/system_health_chip.dart'; // Moved to Composer
// import '../widgets/os_health_widget.dart'; // Moved to Composer
// import '../widgets/last_run_widget.dart'; // Moved to Composer
// import '../widgets/founder_banner.dart'; // Moved to Composer
import '../logic/dashboard_refresh_controller.dart';
// import '../repositories/system_health_repository.dart'; // Removed (D74)
// import '../repositories/last_run_repository.dart'; // Removed (D74)
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

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  // D73: Unified Snapshot SSOT
  final UnifiedSnapshotRepository _unified = UnifiedSnapshotRepository();

  // Legacy repos removed/unused in this view
  // late DashboardRepository _repo; 
  // late SystemHealthRepository _healthRepo;
  // late LastRunRepository _lastRunRepo;

  DashboardPayload? _dashboard;
  SystemHealth? _health;
  SystemHealthSnapshot _healthSnapshot = SystemHealthSnapshot.unknown;
  LastRunSnapshot _lastRunSnapshot = LastRunSnapshot.unknown;
  Map<String, dynamic>? _optionsContext;

  bool _loading = true;
  String? _error;
  late DashboardRefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // D37.02: Initialize Timezones
    TimeUtils.init();

    _refreshController = DashboardRefreshController(
      onRefresh: () async => await _loadData(),
    );

    // Initial load
    _loadData().then((_) {
      _refreshController.start();
    });

    // Forensic Trace
    if (AppConfig.isFounderBuild) {
      debugPrint(
          "FOUNDER=true, keyInjected=true, baseUrl=${AppConfig.apiBaseUrl}");
    }
  }

  // ... dispose/lifecycle ...

  Future<void> _loadData() async {
    if (!_refreshController.isManual) {
      // Don't show full loading spinner on auto-refresh, just let it update
      // But if it's first load (_loading=true), we show it.
      if (_loading) setState(() => _error = null); 
    } else {
       // Manual refresh
       setState(() {
         _loading = true;
         _error = null;
       });
    }

    try {
      // D73: SINGLE SOURCE OF TRUTH FETCH
      final envelope = await _unified.fetch();

      if (mounted) {
        setState(() {
          // 1. Dashboard Module
          final dashData = _unified.getModule('dashboard');
          if (dashData != null) {
             _dashboard = DashboardPayload.fromJson(dashData);
          } else {
             // D73: Partial Availability - handle missing module
             // We can allow _dashboard to be null or generic empty?
             // DashboardComposer handles nulls gracefully-ish
          }

          // 2. Health (Legacy Model)
          // We construct it from 'os_health' or 'misfire' module if available
          final misfireData = _unified.getModule('misfire'); // or os_health?
          if (misfireData != null) {
              _health = SystemHealth.fromJson(misfireData);
          } else {
              _health = SystemHealth.unavailable("SNAPSHOT_MISSING");
          }

          // 3. Health Snapshot (New Model)
          // Usually from os_health
          // final healthSnapData = _unified.getModule('os_health'); 
          // if (healthSnapData != null) _healthSnapshot = SystemHealthSnapshot.fromJson(healthSnapData);

          // 4. Options Context
          _optionsContext = _unified.getModule('options');

          // 5. Last Run
          // _lastRunSnapshot = ... (if in snapshot)

          _loading = false;
          
          // D37.07: Report Locked State
          // Re-resolve state based on new data
           final resolved =
              DataStateResolver.resolve(dashboard: _dashboard, health: _health);
           _refreshController.reportLockedState(resolved.state == DataState.locked);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
    final resolvedState =
        DataStateResolver.resolve(dashboard: _dashboard, health: _health);

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
