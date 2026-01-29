# DataMux V1 Notes

## Domain Contracts
- **Candles:** `fetch_candles(symbol, timeframe, granularity)` -> `DataResult`
- **News:** `fetch_news(symbol)` -> `DataResult` (Stub for now)
- **Options:** `fetch_options(symbol)` -> `DataResult` (Stub for now)
- **Macro:** `fetch_macro()` -> `DataResult` (Stub for now)

## Status Codes
- `LIVE`: Data fetched successfully from a real provider.
- `DEMO`: Data fetched from demo/stub provider (safe fallback).
- `DENIED`: Provider explicitly denied access (401/403/Quota).
- `OFFLINE`: No providers available.

## Health Artifact
- `outputs/os/engine/provider_health.json`
- Tracks last success and cumulative failures.
- Used by `AutoFix` (future) to recommend provider rotation.
