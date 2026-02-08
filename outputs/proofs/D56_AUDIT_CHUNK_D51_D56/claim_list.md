# D56.AUDIT.CHUNK_06 — CLAIM LIST (D51-D56)

**Chunk:** D51 - D56
**Status:** DRAFT

| Claim ID | Seal / Milestone | Primary Assertions | Expected Evidence | Status |
| :--- | :--- | :--- | :--- | :--- |
| **D53.WR.TRUTH** | `SEAL_D53_6_WAR_ROOM_TRUTH...` | War Room V2 "Truth Exposure" (Source Attribution, N/A States). | Code: `lib/widgets/war_room/zones/service_honeycomb.dart` | PENDING |
| **D56.USP** | `SEAL_D56_01_UNIFIED...` | Unified Snapshot Protocol (USP-1) Endpoint. | Code: `backend/api_server.py` (`/lab/war_room/snapshot`) | PENDING |
| **D56.USP.FE** | `SEAL_D56_01_UNIFIED...` | Frontend exclusively uses USP. | Code: `lib/repositories/war_room_repository.dart` | PENDING |
| **D56.POLICY** | `SEAL_D56_01_5_WARROOM...` | Snapshot-Only Policy (Block Legacy). | Code: `lib/services/api_client.dart` (WarRoomPolicyException) | PENDING |
| **D56.HK.API** | `SEAL_D56_HK_1_HOUSEKEEPER...` | Housekeeper Restored API. | Code: `backend/api_server.py` (`/lab/os/housekeeper/run`) | PENDING |
| **D56.PROBES** | `SEAL_D56_01_10_CLOUD...` | Lab Probes (Edge Bypass). | Code: `backend/api_server.py` (`/lab/healthz`) | PENDING |
| **D56.SHIELD** | `SEAL_D56_01_10_CLOUD...` | Auth Shield on Sensitive Routes. | Code: `backend/api_server.py` (Shield Middleware) | PENDING |
| **D56.SMOKE** | `SEAL_D56_01_10_CLOUD...` | Smoke Test Checks Lab Probes. | File: `tools/smoke_cloud_run.ps1` | PENDING |
