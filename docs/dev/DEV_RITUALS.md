# DEV RITUALS (D55.16)

> **Authority:** D55.16
> **Scope:** Local Development & Debugging

## 1. The Pulse Check (Standard Start)
Use this ritual to start the full stack (Frontend + Backend) for local development.

**Command:**
```powershell
./tools/dev_ritual.ps1
```

**What it does:**
1.  Checks if Port 8787 (BFF Proxy) is active.
2.  If not, launches `python tools/dev_proxy/proxy.py` in a new window.
3.  Launches `flutter run -d chrome` attached to the current terminal.

**Result:**
- War Room shows **OS HEALTH: GREEN**.
- Changes to Flutter code hot-reload normally.
- Backend logs are visible in the separate proxy window.

---

## 2. The Blackout Check (Failure Verification)
Use this to verify fail-safe UI states (UNAVAILABLE / UNKNOWN).

**Command:**
```powershell
# Stop any proxy/python instances
Get-Process python* | Stop-Process

# Run strict frontend only
cd market_sniper_app
flutter run -d chrome
```

**Result:**
- War Room MUST show **OS HEALTH: UNKNOWN**.
- Tiles MUST show **UNAVAILABLE** or **N_A**.
- NO red overflow errors (D55.16 fix).

---
