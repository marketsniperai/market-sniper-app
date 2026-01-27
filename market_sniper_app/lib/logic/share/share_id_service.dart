import 'package:shared_preferences/shared_preferences.dart';
import '../market_time_helper.dart'; // Reuse existing time helper
import 'share_library_store.dart'; // Reuse for logging or simple print

class ShareIdService {
  static const String _kCounterKey = 'ms_share_id_counter';
  static const String _kLastDayKey = 'ms_share_id_last_day';

  static Future<String> generateId() async {
    final prefs = await SharedPreferences.getInstance();

    // Day Logic
    final nowEt = MarketTimeHelper.getNowEt();
    // Simplified YYYYMMDD
    final dayStr =
        "${nowEt.year}${nowEt.month.toString().padLeft(2, '0')}${nowEt.day.toString().padLeft(2, '0')}";

    // Reset counter if new day (optional, but prompt says "incremental counter stored locally (bounded 0..999)")
    // If bounded 0..999, maybe global or per day? Best per day to avoid collision with short ID.
    // Let's assume incremental global but wrapped, or just incremental.
    // "day_id (04:00 ET boundary) + incremental counter"
    // So ID: MSR-SHARE-YYYYMMDD-001

    // Check Day Boundary
    final lastDay = prefs.getString(_kLastDayKey) ?? "";
    if (lastDay != dayStr) {
      await prefs.setInt(_kCounterKey, 0);
      await prefs.setString(_kLastDayKey, dayStr);
    }

    int counter = prefs.getInt(_kCounterKey) ?? 0;
    counter++;
    if (counter > 999) counter = 0; // Wrap safety
    await prefs.setInt(_kCounterKey, counter);

    final id = "MSR-SHARE-$dayStr-${counter.toString().padLeft(3, '0')}";

    // Log Creation
    // (Simulate Ledger Write)
    await ShareLibraryStore.logEvent("SHARE_ID_CREATED", {"id": id});

    return id;
  }
}
