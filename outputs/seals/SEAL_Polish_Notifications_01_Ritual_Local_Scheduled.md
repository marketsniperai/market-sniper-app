
# SEAL: Polish.Notifications.01 - Local Scheduled Rituals

## 1. Summary
Implemented local scheduled notifications for the two daily rituals (Morning Briefing @ 9:20 AM ET, Aftermarket Closure @ 4:05 PM ET). The feature is controlled by a persistent toggle in the new Menu Screen.

## 2. Changes
- **Service**: `lib/services/notification_service.dart` handles scheduling, permissions, and cancellation.
- **Menu**: Wired "Notifications" toggle to persisted setting and service logic.
- **Main**: Initialized notification service on app start.
- **Dependencies**: Added `flutter_local_notifications`.

## 3. Implementation Details
- **Scheduling**: Uses `zonedSchedule` (best effort timezone approximation if 'America/New_York' not found, falling back to local).
- **Permissions**: Requests on toggle enable (Android/iOS).
- **Persistence**: `shared_preferences` key `notifications_enabled`.

## 4. Verification
- **Compilation**: Passes `flutter analyze` and `flutter run`.
- **Toggle Logic**:
  - ENABLED -> Requests perm -> Schedules daily.
  - DISABLED -> Cancels all.
- **Hotfix Integration**: Verified with GoogleFonts hotfix.

## 5. Known Limitations
- **Timezone**: v1 logic attempts to set location to 'America/New_York'. If timezone data is missing/locked on device, it logs a warning and uses local time.
- **Routing**: Tap handling currently logs the payload. Deep linking to specific ritual screens is ready for next wiring step.
