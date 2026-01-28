# SEAL: D47.HF14 NEWS RANKING SKELETON

**Date:** 2026-01-27
**Author:** Antigravity (Agent)
**Status:** SEALED (PASS)
**Verification:** Static Analysis + Web Build + Sort Logic Check

## 1. Objective
Implement a deterministic, rules-only ranking engine for NewsDigest to prioritize high-value intel without numeric "impact scores".
- **Ranking Logic:** `Macro > Watchlist > General`.
- **Recency Logic:** `15m > 60m > Today > Older`.
- **Infrastructure:** `NewsRanker` decoupled from source, `NewsDigestItem` updated with optional `symbols`.

## 2. Changes
- **NEW:** `lib/logic/news/news_ranker.dart` (Deterministic sorting engine).
- **MODIFIED:** `lib/models/news/news_digest_model.dart` (Added `symbols` and debug `rankingReason`).
- **MODIFIED:** `lib/logic/news/news_digest_source.dart` (Wired ranker to demo pipeline, populated item symbols).

## 3. Verification Results
### A) Static Analysis
- `flutter analyze`: **PASS** (Zero issues).

### B) Functional Logic
- **Macro Priority:** "Fed" / "rates" keywords force items to top bucket.
- **Watchlist Boost:** Items matching user tickers are promoted above General items.
- **Recency:** Newer items rank higher within their buckets.

## Pending Closure Hook

### Resolved Pending Items
- None

### New Pending Items
- None (Debt covered by HF13 items `PEND_DATA_NEWS_PROVIDER` and `PEND_INTEL_NEWS_IMPACT_ENGINE`).

## 4. Git Status
```
[Included in Final Commit]
```
