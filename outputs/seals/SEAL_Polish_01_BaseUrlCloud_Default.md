
# SEAL: Polish.01 - Base URL Cloud Default

## 1. Discovery
- **Local Default:** `AppConfig.apiBaseUrl` was falling back to `10.0.2.2:8000` via `String.fromEnvironment('API_BASE_URL', defaultValue: ...)` logic.
- **Chip Display:** `SessionWindowStrip` was hardcoded to check for `run.app` substring.

## 2. Changes
- **AppConfig:** Implemented `API_MODE` check. 
  - If `API_MODE` is NOT `local`, it defaults to `_canonicalProdUrl`.
  - Only if `API_MODE=local`, it uses the Localhost URL.
- **UI Chip:** Updated logic to check for `10.0.2.2` explicitly for "LOCAL" label, otherwise "CLOUD".

## 3. Verification
- **Default (Cloud):** `flutter run` -> Defaults to Cloud URL (Verified via Test).
- **Explicit Local:** `flutter run --dart-define=API_MODE=local` -> Defaults to 10.0.2.2 (Verified via Test).

## 4. Commands
- To run Cloud (Standard): `flutter run`
- To run Local: `flutter run --dart-define=API_MODE=local`

## 5. Stop Conditions
- No backend changes.
- UI only updated in status chip.
- Logic is transparent and contained in AppConfig.
