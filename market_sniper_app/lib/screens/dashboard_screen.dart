import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/dashboard_payload.dart';
import '../models/system_health.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/system_health_chip.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  late ApiClient _api;
  DashboardPayload? _dashboard;
  SystemHealth? _health;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api = ApiClient();
    _loadData();
    _startTimer();
    
    // Forensic Trace
    if (AppConfig.isFounderBuild) {
      debugPrint("FOUNDER=true, keyInjected=true, baseUrl=${AppConfig.apiBaseUrl}");
    }
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      _loadData();
    } else if (state == AppLifecycleState.paused) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData(silent: true));
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
       setState(() { _loading = true; _error = null; });
    }
    try {
      final results = await Future.wait([
        _api.fetchDashboard(),
        _api.fetchSystemHealth(),
      ]);
      
      if (mounted) {
        setState(() {
          _dashboard = results[0] as DashboardPayload;
          _health = results[1] as SystemHealth;
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
      onRefresh: () => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null && _dashboard == null) {
      return Center(child: Text("ERROR: $_error", style: const TextStyle(color: AppColors.stateLocked)));
    }
    
    if (_dashboard == null) {
      return const SizedBox.shrink(); // Loading indicator in app bar handles visual feedback
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Loading Indicator (Moved from AppBar)
        if (_loading) 
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: LinearProgressIndicator(minHeight: 2),
          ),

        // Health Surface (Day 09)
        if (_health != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SystemHealthChip(
              health: _health!,
              isFounder: AppConfig.isFounderBuild,
            ),
          ),

        // Header Info
        Text("STATUS: ${_dashboard!.systemStatus}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
        Text("MSG: ${_dashboard!.message}", style: const TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        
        // Dynamic Widgets
        ..._dashboard!.widgets.map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: renderWidget(w),
        )),
        
        const SizedBox(height: 32),
        Center(child: Text("Generated: ${_dashboard!.generatedAt ?? 'Unknown'}", style: const TextStyle(color: AppColors.textDisabled, fontSize: 10))),
      ],
    );
  }
}
