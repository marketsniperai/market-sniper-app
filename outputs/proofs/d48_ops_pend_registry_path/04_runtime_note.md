# Runtime Note: PEND_REGISTRY_PATH

**Action:**
- Updated `backend/verify_day_26_registry.py` to enforce that `primary_files` paths start with `/` (Canonical format relative to repo root).
- Updated `os_registry.json` to prepend `/` to all 36 affected `primary_files` entries.

**Why:**
- Maintains canonical consistency.
- Resolves pending tech debt `PEND_REGISTRY_PATH`.

**Result:**
- Verifier now passes WITH the strict check enabled.
