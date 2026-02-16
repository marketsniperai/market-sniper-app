# SEAL: UNIFIED SNAPSHOT REPOSITORY FOUNDATION
**Date:** 2026-02-13
**Subject:** Creation of Single Source of Truth Repository

## 1. Implementation
- **Repository**: `lib/repositories/unified_snapshot_repository.dart`
  - Singleton pattern.
  - Fetches from `ApiClient.fetchUnifiedSnapshotRaw`.
  - Parses `UnifiedSnapshotEnvelope`.
  - Exposes `lastEnvelope` and `getModule()` for safe access.
- **ApiClient**: `lib/services/api_client.dart`
  - Added `fetchUnifiedSnapshotRaw` to bypass future blocking logic.

## 2. API Contract
- **Endpoint**: `/lab/war_room/snapshot`
- **Method**: `GET`
- **Headers**: Inherits `X-Founder-Key` from AppConfig.

## 3. Usage Pattern
All UI components will now import `UnifiedSnapshotRepository` instead of calling `ApiClient` directly.
```dart
final repo = UnifiedSnapshotRepository();
final envelope = await repo.fetch();
final dashboardData = repo.getModule('dashboard');
```

**Verdict**: FOUNDATION LAID. READY FOR WIRING.
