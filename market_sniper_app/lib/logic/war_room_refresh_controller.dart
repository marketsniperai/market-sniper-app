import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

enum RefreshReason {
  startup,
  auto,
  manual,
}

class WarRoomRefreshController {
  final Future<void> Function() onRefresh;
  Timer? _timer;
  DateTime? _lastRefreshTime;
  DateTime? _lastSuccessTime;
  DateTime? _lastErrorTime;
  bool _isPaused = false;
  bool _isRefreshing = false;

  bool _shouldBackoff = false; // Triggered by UNAVAILABLE or LOCKED state

  WarRoomRefreshController({required this.onRefresh});

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
      if (sinceLast.inSeconds < AppConfig.warRoomManualRefreshCooldownSeconds) {
        if (kDebugMode) print("War Room manual refresh ignored due to cooldown");
        return;
      }
    }
    await _executeRefresh(RefreshReason.manual);
  }

  // Allows the UI to report if state requires backoff (Locked or Unavailable)
  void reportEffectiveState(bool backoffRequired) {
    _shouldBackoff = backoffRequired;
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
      if (kDebugMode) print("War Room Refresh failed: $e");
    } finally {
      _isRefreshing = false;
      _scheduleNextAutoRefresh(); 
    }
  }

  void _scheduleNextAutoRefresh() {
    _timer?.cancel();
    if (_isPaused) return;

    int nextInterval = AppConfig.warRoomAutoRefreshSeconds;
    
    // Governance: Backoff if backoff required (120s) OR error (120s)
    if (_shouldBackoff) {
      nextInterval = AppConfig.warRoomBackoffSeconds;
    } else if (_lastErrorTime != null && _lastSuccessTime != null && _lastErrorTime!.isAfter(_lastSuccessTime!)) {
      nextInterval = AppConfig.warRoomBackoffSeconds;
    }
    
    _timer = Timer(Duration(seconds: nextInterval), () {
      _executeRefresh(RefreshReason.auto);
    });
  }

  
  // Getters for debug/UI
  DateTime? get lastRefreshTime => _lastRefreshTime;
  DateTime? get lastErrorTime => _lastErrorTime;
  bool get isRefreshing => _isRefreshing;
}
