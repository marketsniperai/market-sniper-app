# Recommendation: Economic Calendar Strategy

**Context:** The Calendar tab is currently a "Ghost Surface" (UI exists, Brain missing).

## Strategy: "Artifact-First" Activation

1.  **Define Contract:** Create `outputs/os/calendar/economic_calendar.json` schema.
2.  **Create Engine:** Implement `CalendarEngine` in backend (Stub or Simple at first).
    - *Option A (Fast):* Manual JSON drop in `outputs/os/calendar/` (Founder curated).
    - *Option B (Auto):* Scrape/Fetch from dedicated provider (Future).
3.  **Expose API:** Add `/calendar` endpoint to `api_server.py` that reads the artifact.
4.  **Wire Frontend:** Replace `offline()` call with `CalendarService.fetch()`.

## Immediate Action (Next Step)
Do not leave as "Offline". Implement **Option A (Manual Artifact)** to prove the pipe.
- Create valid `economic_calendar.json` with sample high-impact events.
- Seal the "Pipe" (Backend -> API -> UI) even if data is manually managed initially.
