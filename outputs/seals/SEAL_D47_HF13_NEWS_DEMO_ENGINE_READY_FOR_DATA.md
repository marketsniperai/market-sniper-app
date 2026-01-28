# SEAL: D47.HF13 NEWS DEMO ENGINE (READY FOR DATA)

**Date:** 2026-01-27
**Author:** Antigravity (Agent)
**Status:** SEALED (PASS)
**Verification:** Static Analysis + Web Build + Runtime Demo

## 1. Objective
Transform the "Offline" News tab into a functional "Demo Mode" that showcases the premium UI (Flip Cards, Impact Tags) and establishes the architecture for future real data integration.
- **Demo Engine:** `LocalDemoNewsDigestSource` provides deterministic, high-quality mock data (Macro, Tech, Oil, Crypto).
- **Abstraction:** `NewsDigestSource` interface allows seamless hot-swap to real API provider.
- **UI:** Wired `NewsScreen` to async load from source, showing "DEMO MODE" freshness chip.

## 2. Changes
- **NEW:** `lib/logic/news/news_digest_source.dart` (Abstraction + Demo Impl).
- **MODIFIED:** `lib/models/news/news_digest_model.dart` (Added `DigestFreshness.demo`).
- **MODIFIED:** `lib/screens/news_screen.dart` (Replaced stub with `FutureBuilder` loader, added Demo Mode styling).
- **MODIFIED:** `docs/canon/PENDING_LEDGER.md` (Registered Debt).

## 3. Verification Results
### A) Static Analysis
- `flutter analyze`: **PASS** (Zero fatal issues in new code).

### B) Visual Expectations
- **Header:** "DAILY DIGEST" + "DEMO MODE" (Cyan).
- **Content:** 3-4 Cards (Fed, NVDA, Oil, BTC if watched).
- **Interaction:** Cards flip on tap.

## Pending Closure Hook

### Resolved Pending Items
- None

### New Pending Items
- `PEND_DATA_NEWS_PROVIDER` (Status: OPEN)
- `PEND_INTEL_NEWS_IMPACT_ENGINE` (Status: OPEN)

## 4. Git Status
```
[Included in Final Commit]
```
