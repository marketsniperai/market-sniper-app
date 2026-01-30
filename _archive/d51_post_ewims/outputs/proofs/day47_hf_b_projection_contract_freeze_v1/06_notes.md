# Runtime Note: Projection Contract Freeze V1 (HF-B)

**Date:** D47.HF-B
**Component:** ProjectionOrchestrator, IntradaySeriesSource

## Timeframe Logic
-   **DAILY (Default)**: Uses 5m intraday candles. Source: `DEMO-INTRA` (or Live).
    -   Artifacts: `projection_report.json` (Compat) AND `projection_report_daily.json` (Explicit).
-   **WEEKLY**: Uses Daily candles (Mon-Fri). Source: `DEMO-WEEKLY`.
    -   Artifact: `projection_report_weekly.json`.
    -   **Ghost Logic**: 
        -   If Today is Wednesday: Mon/Tue/Wed are Solid (Past+Now). Thu/Fri are Ghost (Future).
        -   Now Candle is the last solid candle (Wed).

## Determinism
-   Both timeframes utilize seeded randomness (SHA256 of symbol+date+interval) to ensure consistency across re-runs on the same day.
-   Visuals in frontend will not flicker.

## On-Demand Pass-Through
-   `/on_demand/context` now accepts `timeframe` param.
-   It directly requests the matching projection from Orchestrator.
-   Note: Tier limits still apply to the endpoint request.
