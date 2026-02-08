// ignore_for_file: unnecessary_null_aware_assignment, unnecessary_null_in_if_null_operators, invariant_booleans, unnecessary_type_check
import 'dart:async';
import 'package:flutter/material.dart'; // For Color
import '../theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import 'api_client.dart';
import 'elite_badge_resolver.dart';

// D49: Elite Badge Controller
// Polling for OS Awareness Signals
class EliteBadgeController extends ChangeNotifier {
  static final EliteBadgeController _instance = EliteBadgeController._internal();
  factory EliteBadgeController() => _instance;
  EliteBadgeController._internal();

  bool _hasBadge = false;
  String? _badgeText;
  Color? _badgeColor;
  String? _contextualHint;
  Timer? _timer;
  String? _lastCheckedTimestamp;
  int? _freeWindowCountdown;

  bool get hasBadge => _hasBadge;
  String? get badgeText => _badgeText;
  Color? get badgeColor => _badgeColor ?? AppColors.neonCyan;
  String? get contextualHint => _contextualHint;
  int? get freeWindowCountdown => _freeWindowCountdown;

  void init() {
     if (_timer != null) return;
     _poll(); // Initial check
     _timer = Timer.periodic(const Duration(seconds: 60), (_) => _poll());
  }

  void dispose() {
    _timer?.cancel();
  }

  void clearBadge() {
    _hasBadge = false;
    _badgeText = null;
    _contextualHint = null;
    notifyListeners();
  }
  
  void markSeen() {
     clearBadge();
  }

  // New Polling Logic for State + Events
  Future<void> _poll() async {
    try {
       // 1. Fetch Ritual State (for Countdown)
       _freeWindowCountdown = null; // Reset
       bool quietHour = false; // Mocked for now
       
       try {
          final stateMap = await ApiClient().getEliteState();
          if (stateMap.containsKey('elite_monday_free_window')) {
              final window = stateMap['elite_monday_free_window'];
              if (window['enabled'] == true) {
                  _freeWindowCountdown = window['countdown_minutes']; 
              }
          }
       } catch (_) {}

       // 2. Fetch Events (Existing Logic)
       final events = await ApiClient().getEvents(since: _lastCheckedTimestamp);
       
       if (events.isEmpty) {
          notifyListeners(); 
          return;
       }
       
       // Update High Water Mark
       final lastEvent = events.last;
       if (lastEvent['timestamp_utc'] != null) {
          _lastCheckedTimestamp = lastEvent['timestamp_utc'];
       }

       // Analyze Events - Use Resolver on the LATEST meaningful event
       for (final rawEvent in events) {
          if (rawEvent is! Map) continue;
          final e = rawEvent; 
          final type = e['event_type'];
          final details = e['details'] as Map<String, dynamic>?;
          
          final result = EliteBadgeResolver.resolve(type, details, quietHour);
          
          if (result.hasBadge) {
              _hasBadge = true;
              _badgeText = result.text;
              _badgeColor = result.color;
              _contextualHint = result.notificationBody; 
              
              if (result.notificationBody != null) {
                  _notifyLocal("Elite Update", result.notificationBody!);
              }
          } else {
             if (type == "ELITE_FREE_WINDOW_CLOSED") {
                 _hasBadge = false;
                 _badgeText = null;
             }
          }
       }
       
       notifyListeners();

    } catch (e) {
       // Silent fail on poll
    }
  }

  void _notifyLocal(String title, String body) {
     try {
        NotificationService().showNotification(title, body);
     } catch (_) {}
  }
}
