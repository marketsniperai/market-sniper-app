# Event Router V1 Notes

## Taxonomy (Initial Minimum Set)
| Event Type | Severity | Source | Trigger |
| :--- | :--- | :--- | :--- |
| `CACHE_HIT_GLOBAL` | INFO | `ProjectionOrchestrator` | Global Cache found for ticker. |
| `CACHE_HIT_LOCAL` | INFO | `ProjectionOrchestrator` | Local Cache found for ticker. |
| `POLICY_BLOCK` | WARN | `ProjectionOrchestrator` | HF32 Cost Policy limit hit (Failover used). |
| `PROJECTION_COMPUTED` | INFO | `ProjectionOrchestrator` | Pipeline computed fresh data. |
| `TEST_EVENT` | INFO | `VerificationScript` | Verification smoke test. |

## Severity Rules
- **INFO:** Normal operation (Cache hits, successful computations).
- **WARN:** Degraded but functional (Policy block fallback, non-critical N/A).
- **ERROR:** Functional failure (missing artifacts, API errors).
- **CRITICAL:** System integrity failure (Panic, Data Corruption).

## Future Expansion
- Add `PROVIDER_DENIED` explicit events.
- Add `CALIBRATION_START` / `CALIBRATION_END` events (requires stateful monitor).
- Add `MISFIRE` events (hooking MisfireMonitor).
