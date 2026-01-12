import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dashboard_payload.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  late ApiClient _api;
  DashboardPayload? _dashboard;
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
      final data = await _api.fetchDashboard();
      if (mounted) {
        setState(() {
          _dashboard = data;
          _loading = false;
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
    return Scaffold(
      backgroundColor: Colors.black, // Oled dark
      appBar: AppBar(
        title: const Text("MARKET SNIPER v0"),
        backgroundColor: AppConfig.isFounderBuild ? Colors.purple[900] : Colors.grey[900],
        actions: [
          if (_loading) const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null && _dashboard == null) {
      return Center(child: Text("ERROR: $_error", style: const TextStyle(color: Colors.red)));
    }
    
    if (_dashboard == null) {
      return const SizedBox.shrink(); // Loading indicator in app bar handles visual feedback
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Info
        Text("STATUS: ${_dashboard!.systemStatus}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
        Text("MSG: ${_dashboard!.message}", style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        
        // Dynamic Widgets
        ..._dashboard!.widgets.map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: renderWidget(w),
        )),
        
        const SizedBox(height: 32),
        Center(child: Text("Generated: ${_dashboard!.generatedAt ?? 'Unknown'}", style: const TextStyle(color: Colors.grey, fontSize: 10))),
      ],
    );
  }
}
