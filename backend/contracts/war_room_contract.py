"""
D56.01.9: War Room Contract (Single Source of Truth).
Defines the strict schema contracts for War Room Snapshot.
Used by:
1. Backend (Hydration)
2. Smoke Tests (Verification)
"""

# The explicit list of keys that MUST be present in the snapshot "modules" map.
# If a provider is missing, the backend MUST hydrate it with an "UNAVAILABLE" stub.
REQUIRED_KEYS = [
    "autopilot",
    "housekeeper",
    "misfire",
    "iron_os",
    "universe",
    "iron_lkg",
    "drift",
    "replay",
    "findings",
    "autofix_tier1",
    "autofix_decision_path",
    "misfire_root_cause",
    "self_heal_confidence",
    "self_heal_what_changed",
    "cooldown_transparency",
    "red_button",
    "misfire_tier2",
    "options",
    "macro",
    "evidence",
    "canon_debt_radar"
]
