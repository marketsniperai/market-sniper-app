import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

enum RefreshReason {
  startup,
  auto,
  manual,
}

class DashboardRefreshController {
  final Future<void> Function() onRefresh;
  Timer? _timer;
  DateTime? _lastRefreshTime;
  DateTime? _lastSuccessTime;
  DateTime? _lastErrorTime;
  bool _isPaused = false;
  bool _isRefreshing = false;

  bool _lastWasLocked = false;

  DashboardRefreshController({required this.onRefresh});

  // Start the auto-refresh timer logic
  void start() {
    _scheduleNextAutoRefresh();
  }

  // Stop/Dispose
  void dispose() {
    _timer?.cancel();
  }

  // Lifecycle hooks
  void pause() {
    _isPaused = true;
    _timer?.cancel();
  }

  void resume() {
    if (_isPaused) {
      _isPaused = false;
      _scheduleNextAutoRefresh();
    }
  }

  // Manual Trigger
  Future<void> requestManualRefresh() async {
    // Check Cooldown
    if (_lastRefreshTime != null) {
      final sinceLast = DateTime.now().difference(_lastRefreshTime!);
      if (sinceLast.inSeconds < AppConfig.manualRefreshCooldownSeconds) {
        if (kDebugMode) print("Manual refresh ignored due to cooldown");
        return;
      }
    }
    await _executeRefresh(RefreshReason.manual);
  }

  // Allows the UI to report if the state was locked, impacting next schedule
  void reportLockedState(bool isLocked) {
    _lastWasLocked = isLocked;
  }

  Future<void> _executeRefresh(RefreshReason reason) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();

    try {
      await onRefresh();
      _lastSuccessTime = DateTime.now();
      _lastErrorTime = null;
    } catch (e) {
      _lastErrorTime = DateTime.now();
      if (kDebugMode) print("Refresh failed: $e");
    } finally {
      _isRefreshing = false;
      _scheduleNextAutoRefresh();
    }
  }

  void _scheduleNextAutoRefresh() {
    _timer?.cancel();
    if (_isPaused) return;

    int nextInterval = AppConfig.dashboardAutoRefreshSeconds;

    // Governance: Backoff if locked (120s) OR error (120s)
    // Error takes precedence? Or Locked? Both are 120s in this spec.
    if (_lastWasLocked) {
      nextInterval = 120; // Hardcoded per D37.07 spec for Locked
    } else if (_lastErrorTime != null &&
        _lastSuccessTime != null &&
        _lastErrorTime!.isAfter(_lastSuccessTime!)) {
      nextInterval = AppConfig.dashboardErrorBackoffSeconds;
    }

    _timer = Timer(Duration(seconds: nextInterval), () {
      _executeRefresh(RefreshReason.auto);
    });
  }

  // Getters for debug/UI
  DateTime? get lastRefreshTime => _lastRefreshTime;
  DateTime? get lastErrorTime => _lastErrorTime;
}
