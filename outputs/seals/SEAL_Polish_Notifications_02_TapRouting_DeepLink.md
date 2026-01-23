
# SEAL: Polish.Notifications.02 - Tap Routing & Deep Linking

## 1. Summary
Implemented the deep linking logic for local notifications. Tapping a "Ritual" notification now routes users to the correct contextual screen or a "Ritual Preview" upsell if they lack access.

## 2. Changes
- **Router**: `lib/services/notification_router.dart` handles payload logic (`ritual:briefing`, `ritual:aftermarket`).
- **Preview Screen**: `lib/screens/ritual_preview_screen.dart` serves as the destination for non-Elite/Founder users.
- **Service Update**: `NotificationService` now holds a `GlobalKey<NavigatorState>` to perform context-free navigation from the background/terminated state.
- **Main**: Wired `navigatorKey` to `MaterialApp` and injected it into `NotificationService`.

## 3. Routing Logic
- **Briefing**: Routes to `DashboardScreen` (canonical home) if allowed.
- **Aftermarket**: Routes to `DashboardScreen` then pushes `WarRoomScreen`.
- **Access Control**: Currently checks `AppConfig.isFounderBuild` as the authority (matches requested logic). Non-founders see `RitualPreviewScreen`.

## 4. Verification
- **Compilation**: Passes `flutter analyze`.
- **Manual Test**: Added a debug button (Founder Only) in Menu to verify `RitualPreviewScreen` rendering.
- **Integration**: Tapping a real notification triggers `NotificationRouter.route` via the `onDidReceiveNotificationResponse` callback.

## 5. Next Steps
- Implement real "Morning Briefing" specific UI if different from Dashboard.

## 6. Compilation Restoration
- **MenuScreen**: Fixed syntax error (`]`) and refined conditional UI for Founder features.
- **PreviewScreen**: Fixed font accessor case.
- **Status**: Restored and building.

