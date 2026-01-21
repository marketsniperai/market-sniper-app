import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import 'market_time_helper.dart';
import 'trial_engine.dart';
import 'try_me_scheduler.dart';

enum EliteAccessMode { none, trial, tryme } // Fixed casing

class EliteAccessResult {
  final bool isUnlocked;
  final EliteAccessMode mode;
  final String? systemNotice; // Null if no notice needed

  EliteAccessResult({
    required this.isUnlocked,
    required this.mode,
    this.systemNotice,
  });
}

class EliteAccessWindowController {
  static const String _kLedgerPrefix = 'ms_elite_access_ledger_';
  // Stable Keys from Policy
  static const String _kKeyUnlocked = "TRYME_UNLOCKED";
  static const String _kKeyWarn5Min = "TRYME_5MIN_WARN";
  static const String _kKeyClosed = "TRYME_CLOSED";

  static Future<EliteAccessResult> resolve() async {
    // 1. Founder Bypass (Always On, No Notices)
    if (AppConfig.isFounderBuild) {
      return EliteAccessResult(isUnlocked: true, mode: EliteAccessMode.none);
    }

    // 2. Derive Institutional Day ID (04:00 ET Boundary)
    final nowEt = MarketTimeHelper.getNowEt();
    final dayId = _getInstitutionalDayId(nowEt);

    // 3. Try-Me Window Logic
    if (TryMeScheduler.isTryMeWindowNow()) {
      // It's Monday 09:20-10:20
      final nowTime = nowEt.hour + (nowEt.minute / 60.0);
      bool is5MinWarn = (nowTime >= 10.25 && nowTime < 10.333); // 10:15 - 10:20

      String? notice;
      if (is5MinWarn) {
        if (await _checkAndBurnOneTimeNotice(dayId, _kKeyWarn5Min)) {
          notice = "5 minutes remaining in Try-Me Hour.";
        }
      } else {
        // Unlocked Notice (Start of window)
        // If we haven't shown UNLOCKED for this day yet.
        if (await _checkAndBurnOneTimeNotice(dayId, _kKeyUnlocked)) {
           notice = "Try-Me Hour active. Elite FULL access temporarily unlocked.";
        }
      }

      return EliteAccessResult(
        isUnlocked: true, 
        mode: EliteAccessMode.tryme,
        systemNotice: notice
      );
    }

    // 4. Closed Notice (Post-Window)
    // Only if it IS Monday, it IS after window, and we haven't said Closed yet.
    // AND optionally: check if we participated? (skipped for simplicity/robustness as per previous D45.07 logic)
    if (nowEt.weekday == DateTime.monday) {
       final nowTime = nowEt.hour + (nowEt.minute / 60.0);
       if (nowTime >= 10.333) {
           if (await _checkAndBurnOneTimeNotice(dayId, _kKeyClosed)) {
              return EliteAccessResult(
                 isUnlocked: false,
                 mode: EliteAccessMode.none,
                 systemNotice: "Try-Me Hour has ended. Elite access reverted."
              );
           }
       }
    }

    // 5. Trial Logic
    if (!TrialEngine.isComplete) {
       return EliteAccessResult(
         isUnlocked: true,
         mode: EliteAccessMode.trial
       );
    }

    // 6. Default Locked
    return EliteAccessResult(isUnlocked: false, mode: EliteAccessMode.none);
  }

  // Idempotency: Returns true if notice should be delivered (first time).
  // Immediately marks as delivered (Burn).
  static Future<bool> _checkAndBurnOneTimeNotice(String dayId, String noticeKey) async {
    final prefs = await SharedPreferences.getInstance();
    // Stable Event ID: ms_elite_access_ledger_2025-01-21_TRYME_UNLOCKED
    final eventId = "${_kLedgerPrefix}${dayId}_$noticeKey";
    
    if (prefs.containsKey(eventId)) {
      return false; // Already delivered
    }
    
    await prefs.setBool(eventId, true);
    return true;
  }
  
  // Helper: 04:00 ET rollover
  static String _getInstitutionalDayId(DateTime et) {
     final boundary = DateTime(et.year, et.month, et.day, 4, 0);
     if (et.isBefore(boundary)) {
       // Belongs to previous day
       final prev = et.subtract(const Duration(days: 1));
       return "${prev.year}-${prev.month.toString().padLeft(2,'0')}-${prev.day.toString().padLeft(2,'0')}";
     }
     return "${et.year}-${et.month.toString().padLeft(2,'0')}-${et.day.toString().padLeft(2,'0')}";
  }
}

