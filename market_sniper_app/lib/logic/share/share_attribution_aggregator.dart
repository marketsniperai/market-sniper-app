import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Reuse for day boundary logic

class ShareAttributionData {
  final String status; // LIVE, OFFLINE, NO_DATA
  final int shares24h;
  final int shares7d;
  final int clicks24h;
  final int clicks7d;
  final double clickRate7d;
  final Map<String, int> topSurfaces; // "Dashboard": 10
  final List<Map<String, dynamic>>
      dailyTable; // [{dayId: "2025-01-21", shares: 5, clicks: 1}]

  const ShareAttributionData({
    required this.status,
    this.shares24h = 0,
    this.shares7d = 0,
    this.clicks24h = 0,
    this.clicks7d = 0,
    this.clickRate7d = 0.0,
    this.topSurfaces = const {},
    this.dailyTable = const [],
  });
}

class ShareAttributionAggregator {
  static const String _kTelemetryKey = 'ms_share_telemetry_buffer';
  static const int _kMaxEvents = 2000;

  static Future<ShareAttributionData> aggregate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? logs = prefs.getStringList(_kTelemetryKey);

      if (logs == null || logs.isEmpty) {
        return const ShareAttributionData(status: "NO_DATA");
      }

      // Bounds check
      var eventsToProcess = logs;
      if (logs.length > _kMaxEvents) {
        eventsToProcess = logs.sublist(logs.length - _kMaxEvents);
      }

      // Aggregators
      int s24 = 0;
      int s7d = 0;
      int c24 = 0;
      int c7d = 0;
      Map<String, int> surfaceCounts = {};
      Map<String, Map<String, int>> dailyStats =
          {}; // "2025-01-21": {"shares": 0, "clicks": 0}

      final now = DateTime.now();
      final day24h = now.subtract(const Duration(hours: 24));
      final day7d = now.subtract(const Duration(days: 7));
      final day14d = now.subtract(const Duration(days: 14));

      for (var logStr in eventsToProcess) {
        try {
          final map = jsonDecode(logStr);
          final tsStr = map['timestamp'] as String?;
          final event = map['event'] as String?;
          final details = map['details'] as Map<String, dynamic>? ?? {};

          if (tsStr == null || event == null) continue;

          final ts = DateTime.parse(tsStr);
          if (ts.isBefore(day14d)) continue; // ignore older than 14d

          // Compute Day ID (canonical 04:00 boundary)
          // Since TimeUtils might expect ET, and logs are UTC/Local from now(),
          // we'll approximate using local or convert if we had zone config.
          // For now, simple standard: subtract 4 hours?
          // Wait, reuse logic if possible. `TimeUtils.getNowEt()` works for "now",
          // but converting arbitrary TS to ET is hard without TZ lib.
          // Simplification: Use Local Time relative to 4am.
          final dayId = _getDayId(ts);

          final is24h = ts.isAfter(day24h);
          final is7d = ts.isAfter(day7d);

          if (event == "SHARE_EXPORTED" || event == "SHARE_ID_CREATED") {
            if (is24h) s24++;
            if (is7d) s7d++;

            // Daily Table
            dailyStats.putIfAbsent(dayId, () => {"shares": 0, "clicks": 0});
            dailyStats[dayId]!["shares"] =
                (dailyStats[dayId]!["shares"] ?? 0) + 1;
          } else if (event == "CTA_CLICKED" || event == "CTA_UPGRADE_CLICKED") {
            if (is24h) c24++;
            if (is7d) c7d++;

            // Daily Table
            dailyStats.putIfAbsent(dayId, () => {"shares": 0, "clicks": 0});
            dailyStats[dayId]!["clicks"] =
                (dailyStats[dayId]!["clicks"] ?? 0) + 1;

            // Surface
            final surface =
                details['context'] ?? details['source'] ?? "unknown";
            surfaceCounts[surface] = (surfaceCounts[surface] ?? 0) + 1;
          }
        } catch (e) {
          // ignore malformed
        }
      }

      // Compute Rates & Cleanup
      double rate = s7d > 0 ? (c7d / s7d) : 0.0;

      // Sort Daily (Newest First)
      List<Map<String, dynamic>> finalDaily = [];
      final days = dailyStats.keys.toList()..sort((a, b) => b.compareTo(a));
      for (var d in days.take(14)) {
        final finalStatsForDay = dailyStats[d]!;
        finalDaily.add({
          "dayId": d,
          "shares": finalStatsForDay["shares"],
          "clicks": finalStatsForDay["clicks"]
        });
      }

      return ShareAttributionData(
        status: "LIVE",
        shares24h: s24,
        shares7d: s7d,
        clicks24h: c24,
        clicks7d: c7d,
        clickRate7d: rate,
        topSurfaces: surfaceCounts,
        dailyTable: finalDaily,
      );
    } catch (e) {
      return const ShareAttributionData(status: "PARTIAL");
    }
  }

  static String _getDayId(DateTime ts) {
    // Boundary 04:00.
    // If hour < 4, it's previous day.
    final adj = ts.hour < 4 ? ts.subtract(const Duration(days: 1)) : ts;
    return "${adj.year}-${adj.month.toString().padLeft(2, '0')}-${adj.day.toString().padLeft(2, '0')}";
  }
}
