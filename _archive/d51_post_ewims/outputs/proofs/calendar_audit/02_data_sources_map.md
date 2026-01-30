# Calendar Data Sources Map

**Current State:** D47 (Audit)

## Data Flow
```mermaid
graph LR
    UI[CalendarScreen] -->|Static Call| VM[EconomicCalendarViewModel.offline]
    VM -->|Hardcoded| OFF[Offline State]
```

## Inventory
- **Source:** Hardcoded Static Method (`EconomicCalendarViewModel.offline()`)
- **Transport:** None (In-Memory)
- **Artifact:** None
- **Endpoint:** None

## Status
- **Freshness:** ALWAYS `OFFLINE`
- **Integrity:** N/A (Stub)
