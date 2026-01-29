| Consumer Surface | Requests | Value | Gating Logic | Fallback |
| :--- | :--- | :--- | :--- | :--- |
| `EliteInteractionSheet` | `GET /elite/what_changed` | Shows diff of OS changes | `EliteAccessWindowController.resolve()` | "Snapshot Unavailable" |
| `EliteInteractionSheet` | `GET /elite/context/status` | Shows engine status | `EliteAccessWindowController.resolve()` | "Status Unavailable" |
| `EliteInteractionSheet` | `GET /elite/agms/recall` | Recalls past context | `_tier.name` (free/plus/elite) | "No Recall Available" |
| `EliteMentorBridgeButton` | `EliteInteractionSheet` (Nav) | Triggers explanation | `isLocked` check | "ELITE MENTORSHIP LOCKED" |
| `SharePreviewSheet` | - | Watermark Tier Label | `PremiumStatusResolver.currentTier` | "FREE" |
| `TimeTravellerChart` | - | Future Projection | `isElite` check | "Upgrade to Elite" SnackBar |
| `TacticalPlaybookBlock` | - | Tactical Specifics | `isElite` check | "Upgrade to Elite" SnackBar |
| `EvidenceGhostOverlay` | - | Ghost Mode Indicator | `isElite` check | Hidden |
