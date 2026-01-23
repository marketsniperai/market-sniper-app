
# SEAL: Polish.FounderLaw.01 - Always-On Access

## 1. Summary
Enforced "Founder Law": Founders have immediate, ungated access to all premium features and rituals. The `AccessPolicy` guard now centralizes this logic.

## 2. Changes
- **Guard**: Created `lib/guards/access_policy.dart`
  - `founderAlwaysOn` => Returns true if `AppConfig.isFounderBuild`.
  - `canAccessRituals` / `canAccessPremium` => Delegates to `founderAlwaysOn`.
- **Routing**: `NotificationRouter` now checks `AccessPolicy`. Founders bypass `RitualPreviewScreen` and go straight to content.
- **Debug**: Updated `MenuScreen` debug button to verify the routing logic. If Founder, it simulates a bypass (SnackBar + Nav); if not, it shows Preview.

## 3. Verification
- **Test**: "DEBUG: Test Ritual Routing" button in Menu.
- **Result (Founder)**: Shows SnackBar "Founder Law: Bypassing Preview" and navigates to content.
- **Result (Non-Founder)**: Shows Standard Preview Screen.
- **Compilation**: Passes `flutter analyze`.

## 4. Next Steps
- Implement real User Entitlements in `AccessPolicy` when backend is available (for non-founders).
