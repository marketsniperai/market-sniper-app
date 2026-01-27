# Artifact Expectations

Audit of artifact readers in the codebase.

## Recognized Artifacts

| Artifact Name | Reader Location | Fields Used | Status |
|---|---|---|---|
| `day_memory_store.json` | `lib/logic/day_memory_store.dart` | Whole file? | Implemented |
| `watchlist_actions_ledger.jsonl` | `lib/logic/watchlist_last_analyzed_resolver.dart`, `lib/logic/watchlist_ledger.dart` | Ledger events | Implemented |
| `session_thread_memory_store.json` | `lib/logic/session_thread_memory_store.dart` | Whole file | Implemented |
| `os_premium_feature_matrix.json` | `lib/models/premium/premium_matrix_model.dart` | Mock load matching SSOT | Stub / Mock |
| `on_demand_history_store.json` | `lib/logic/on_demand_history_store.dart` | Whole file | Implemented |
| `os_share_cta_ledger.jsonl` | `lib/logic/share/share_library_store.dart` | Comment only | Stub |
| `Briefing.json` | `lib/logic/command_center/command_center_builder.dart` | Status check | Stub / Ref |
| `Aftermarket.json` | `lib/logic/command_center/command_center_builder.dart` | Status check | Stub / Ref |

## Stubs and Fallbacks

Found extensive use of "N/A" fallbacks in `WarRoomRepository` and `DashboardComposer`.
"CALIBRATING" system status is present in `SystemHealthChip`.

### Artifact Usage Notes

- **War Room & Dashboard**: Heavily defensive coding with `?? 'N/A'` or `?? "N/A"`.
- **Premium Matrix**: Explicit comment `// Mock load matching SSOT outputs/os/os_premium_feature_matrix.json`.
- **Watchlist**: Uses `.jsonl` for append-only ledger, seemingly fully implemented.
