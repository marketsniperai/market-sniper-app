# D59 Decision Pack

**Total Unknowns:** 31

| Path | Method | Proposal | Category | Reason |
| :--- | :--- | :--- | :--- | :--- |
| `/agms/handoff/ledger/tail` | GET | **PUBLIC_PRODUCT** | PUBLIC_CANDIDATE | AGMS Read-Only |
| `/agms/intelligence` | GET | **PUBLIC_PRODUCT** | PUBLIC_CANDIDATE | AGMS Read-Only |
| `/agms/ledger/tail` | GET | **PUBLIC_PRODUCT** | PUBLIC_CANDIDATE | AGMS Read-Only |
| `/agms/shadow/ledger/tail` | GET | **PUBLIC_PRODUCT** | PUBLIC_CANDIDATE | AGMS Read-Only |
| `/agms/shadow/suggestions` | GET | **PUBLIC_PRODUCT** | PUBLIC_CANDIDATE | AGMS Read-Only |
| `/autofix` | GET | **PUBLIC_PRODUCT** | POTENTIAL_PUBLIC | General GET |
| `/blackbox/ledger/tail` | GET | **LAB_INTERNAL** | LAB_INTERNAL | Ops/Forensics path |
| `/blackbox/snapshots` | GET | **LAB_INTERNAL** | LAB_INTERNAL | Ops/Forensics path |
| `/blackbox/status` | GET | **LAB_INTERNAL** | LAB_INTERNAL | Ops/Forensics path |
| `/dojo/status` | GET | **LAB_INTERNAL** | LAB_INTERNAL | Ops/Forensics path |
| `/dojo/tail` | GET | **LAB_INTERNAL** | LAB_INTERNAL | Ops/Forensics path |
| `/elite/agms/recall` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/chat` | POST | **UNKNOWN_ZOMBIE** | ELITE_GATED | Elite Cost/Write |
| `/elite/context/status` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/explain/status` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/micro_briefing/open` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/os/snapshot` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/reflection` | POST | **UNKNOWN_ZOMBIE** | ELITE_GATED | Elite Cost/Write |
| `/elite/ritual` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/ritual/{ritual_id}` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/script/first_interaction` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/settings` | POST | **UNKNOWN_ZOMBIE** | ELITE_GATED | Elite Cost/Write |
| `/elite/state` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/elite/what_changed` | GET | **UNKNOWN_ZOMBIE** | ELITE_READ | Elite Read (Check safety) |
| `/events/latest` | GET | **PUBLIC_PRODUCT** | POTENTIAL_PUBLIC | General GET |
| `/evidence_summary` | GET | **PUBLIC_PRODUCT** | POTENTIAL_PUBLIC | General GET |
| `/immune/status` | GET | **LAB_INTERNAL** | LAB_INTERNAL | Ops/Forensics path |
| `/immune/tail` | GET | **LAB_INTERNAL** | LAB_INTERNAL | Ops/Forensics path |
| `/misfire` | GET | **PUBLIC_PRODUCT** | POTENTIAL_PUBLIC | General GET |
| `/tuning/status` | GET | **PUBLIC_PRODUCT** | POTENTIAL_PUBLIC | General GET |
| `/tuning/tail` | GET | **PUBLIC_PRODUCT** | POTENTIAL_PUBLIC | General GET |
