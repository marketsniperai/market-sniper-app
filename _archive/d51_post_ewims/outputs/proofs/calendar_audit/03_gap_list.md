# Gap List: Economic Calendar

| Component | Status | Gap Description |
| :--- | :--- | :--- |
| **Backend Engine** | MISSING | No engine to source/parse economic events. |
| **Truth Artifact** | MISSING | No canonical JSON (e.g. `economic_calendar.json`) exists. |
| **API Endpoint** | MISSING | No `/calendar` endpoint in `api_server.py`. |
| **Frontend Service** | MISSING | UI calls static `offline()` method; no HTTP wiring. |
| **Data Source** | MISSING | No external or internal feed connected (e.g. news/macro). |
| **Governance** | MISSING | No refresh rules, caching policies, or state definitions. |

## Criticality
**HIGH.** The tab exists but functions only as a placeholder. It provides zero utility in its current state.
