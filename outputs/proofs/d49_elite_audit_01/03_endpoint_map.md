| Endpoint | Handler | Purpose | Artifact Consumed |
| :--- | :--- | :--- | :--- |
| `GET /elite/explain/status` | `elite_explain_status` | Status of explanation service | `os_explain_router_status.json` |
| `GET /elite/os/snapshot` | `elite_os_snapshot` | Read-only OS snapshot for context | `run_manifest.json`, `os_risk_state.json` |
| `GET /elite/script/first_interaction` | `elite_first_interaction` | Welcome script for Elite user | `os_elite_first_interaction_script.json` |
| `GET /elite/context/status` | `elite_context_status` | Detailed engine status for context | `os_context_engine_status.json` |
| `GET /elite/what_changed` | `elite_what_changed` | Diff of authorized changes | `os_before_after_diff.json` |
| `GET /elite/micro_briefing/open` | `elite_micro_briefing_open` | Daily/Session briefing | `os_elite_micro_briefing_protocol.json` |
| `GET /elite/agms/recall` | `elite_agms_recall` | Contextual recall for AGMS | `os_elite_agms_recall_contract.json` |
