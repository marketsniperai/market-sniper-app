# Reliability Outcomes (D48.BRAIN.04)

## Methodology
In V1, "Realized Outcome" is defined as:
- **Daily Timeframe:** The Close price of the *same session* (if computed intraday) or *next session* (if computed pre-market)?
- **Decision:** Current logic uses `IntradaySeries.nowCandle.c`. This assumes the Series Source has loaded the "Latest" data relevant to the projection.
- **Bounds Check:** We check if `realized_close` is within `lower_2std` and `upper_2std` of the scenario envelope.

## Validation
- `verify_d48_brain_04.py` demonstrates the full loop:
  1. Generate Projection -> Write to Ledger.
  2. Mock "Future" Data (Intraday Series).
  3. Reconcile -> Write to Outcomes.
  4. Generate Report -> Aggregated Stats.

## Limitations (V1)
- Reconciler currently relies on `IntradaySeriesSource` which may imply pipeline execution. In production, this should be a lightweight fetch from a Price Database.
- "Realized" is defined simplistically as "Latest available price". Ideal for Intraday tracking, less precise for Swing tracking (need specific timestamps).
