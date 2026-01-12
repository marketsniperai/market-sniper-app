# AUTH & GATES CANON (G0.CANON_1)

**Authority:** IMMUTABLE

## 1. Headers Contract
The following headers are authoritative.

| Header | Purpose | Producer | Persistence |
| :--- | :--- | :--- | :--- |
| **X-Founder-Key** | High-privilege access | Client (Founder) | Ephemeral (Session) |
| **X-Client-Build** | Deployment Tracking | Client (App) | Logged |
| **X-Founder-Trace** | Forensic Visibility | Backend | Response Only |

## 2. Environment Flags (Backend)
- `FOUNDER_BUILD`: (Bool) Enables/Disables trace injection.
- `FOUNDER_AUTH_MODE`: (Enum: `STRICT`, `OPEN`, `OFF`) Controls `/lab/` access.
    - **STRICT**: Requires `X-Founder-Key` match.
    - **OPEN**: (Dev Only) Allows bypass.
    - **OFF**: All `/lab/` endpoints return 404.

## 3. The "Founder Mode" Law
Founder Mode is a **System Override**, not a Feature.
- It must **never** be exposed to an end-user.
- It is triggered **only** by explicit headers or environment flags.
- When active, it forces `Visual Transparency` (ErrorCards instead of empty space).

## 4. Default Fail Behaviors
- **Public API**: Fail Open (Serve stale data if live is missing).
- **Ops API**: Fail Hidden (Return 404 if unauthorized).
- **Entitlement**: Fail Closed (Deny access if DB is down).
