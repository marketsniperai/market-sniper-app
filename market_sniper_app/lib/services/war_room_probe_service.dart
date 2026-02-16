import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class WarRoomProbeService {
  static Future<void> runProbes() async {
    if (!kDebugMode || !AppConfig.isFounderBuild) return;

    final baseUrl = AppConfig.apiBaseUrl;
    debugPrint("WAR_ROOM_PROBE_CTX baseUrl=$baseUrl founder=${AppConfig.isFounderBuild} web=$kIsWeb");

    // D73: SSOT MIGRATION - Direct Probes
    // Access must go through UnifiedSnapshotRepository.

    // NET Probe: Health
    final healthUrl = "$baseUrl/health_ext";
    try {
      final sw = Stopwatch()..start();
      final resp = await http.get(Uri.parse(healthUrl));
      sw.stop();
      debugPrint("WAR_ROOM_PROBE_NET health_ext code=${resp.statusCode} ms=${sw.elapsedMilliseconds}");
    } catch (e) {
      debugPrint("WAR_ROOM_PROBE_NET health_ext error=$e");
    }

    // NET Probe: Snapshot
    final snapUrl = "$baseUrl/lab/war_room/snapshot";
    try {
      final sw = Stopwatch()..start();
      final resp = await http.get(Uri.parse(snapUrl));
      sw.stop();
      debugPrint("WAR_ROOM_PROBE_NET snapshot code=${resp.statusCode} ms=${sw.elapsedMilliseconds}");
      if (resp.statusCode == 200) {
         try {
           final json = jsonDecode(resp.body);
           if (json is Map<String, dynamic>) {
              // Log top-level keys only
              debugPrint("WAR_ROOM_PROBE_NET snapshot keys=${json.keys.toList()}");
           } else {
              debugPrint("WAR_ROOM_PROBE_NET snapshot rawType=${json.runtimeType}");
           }
         } catch (e) {
            debugPrint("WAR_ROOM_PROBE_PARSE snapshot_manual error=$e");
         }
      }
    } catch (e) {
      debugPrint("WAR_ROOM_PROBE_NET snapshot error=$e");
    }
  }
}
