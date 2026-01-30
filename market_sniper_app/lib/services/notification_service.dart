import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  // Ritual Times (ET)
  static const int morningBriefingHour = 9;
  static const int morningBriefingMinute = 20; // 9:20 AM ET
  static const int aftermarketClosureHour = 16;
  static const int aftermarketClosureMinute = 5; // 4:05 PM ET

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) { 
        _isInitialized = true; 
        return; 
    }

    // tz.initializeTimeZones(); // Web Compat Disable
    // try {
    //   tz.setLocalLocation(tz.getLocation('America/New_York'));
    // } catch (e) {
    //   debugPrint(
    //       "NotificationService: Could not set ET timezone, trailing local time. $e");
    // }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    _ensureScheduleConsistency();
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint("NotificationService: Tapped payload=${response.payload}");
    if (_navigatorKey != null && response.payload != null) {
      NotificationRouter.route(_navigatorKey!, response.payload);
    }
  }

  Future<void> _ensureScheduleConsistency() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;
    if (enabled) {
      await scheduleDailyRituals();
    } else {
      await cancelAllRituals();
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      final granted = await requestPermissions();
      if (granted) {
        await scheduleDailyRituals();
      } else {
        debugPrint(
            "NotificationService: Permission denied, but enabled in prefs.");
      }
    } else {
      await cancelAllRituals();
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  Future<void> scheduleDailyRituals() async {
    await cancelAllRituals();

    debugPrint("NotificationService: Scheduling Rituals (Disabled for Web V1)...");
    
    // Stubbed for Web Compatibility
    /*
    await _scheduleDaily(
      id: 1,
      title: "Morning Briefing Ready",
      body: "Institutional context for the opening bell.",
      hour: morningBriefingHour,
      minute: morningBriefingMinute,
      payload: "ritual:briefing",
    );

    await _scheduleDaily(
      id: 2,
      title: "Aftermarket Closure",
      body: "Finalize your ledger. The session has ended.",
      hour: aftermarketClosureHour,
      minute: aftermarketClosureMinute,
      payload: "ritual:aftermarket",
    );
    */
  }

  /*
  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'ritual_channel',
      'Ritual Notifications',
      channelDescription: 'Daily market rituals',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint("NotificationService: Scheduled '$title' for $scheduledDate");
    } catch (e) {
      debugPrint("NotificationService: Failed to schedule id=$id. Error: $e");
    }
  }
  */

  Future<void> cancelAllRituals() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
    debugPrint("NotificationService: Cancelled all rituals.");
  }

  // D49: Immediate Notification (Local)
  Future<void> showNotification(String title, String body, {String? payload}) async {
    if (kIsWeb) {
      debugPrint("NotificationService (Web): $title - $body");
      return; 
    }
    
    // Ensure permissions or enabled check?
    // We assume caller checks preferences or we check here:
    if (!await isEnabled()) return;

    const androidDetails = AndroidNotificationDetails(
      'elite_channel',
      'Elite Notifications',
      channelDescription: 'Immediate alerts from Elite',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      // ID 999 for generic immediate alerts, or random?
      // Using 999 overwrites previous. That's fine for now.
      await _notifications.show(
        999,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint("NotificationService: Failed to show notification. $e");
    }
  }
}
