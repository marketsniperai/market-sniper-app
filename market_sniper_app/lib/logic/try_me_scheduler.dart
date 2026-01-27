import 'market_time_helper.dart';
import 'trial_engine.dart';

class TryMeScheduler {
  static bool isTryMeWindowNow() {
    // Only valid if trial is complete (guests only)
    if (!TrialEngine.isComplete) return false;

    final nowEt = MarketTimeHelper.getNowEt();

    // Monday?
    if (nowEt.weekday != DateTime.monday) return false;

    // 09:20 - 10:20 ET
    final time = nowEt.hour + (nowEt.minute / 60.0);
    // 9:20 is 9.333...
    // 10:20 is 10.333...
    return time >= 9.33 && time <= 10.33;
  }

  static String getNextWindowInfo() {
    // Simple helper string
    return "Mon 09:20-10:20 ET";
  }
}
