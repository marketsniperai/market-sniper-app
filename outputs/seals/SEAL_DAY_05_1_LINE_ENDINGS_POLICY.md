# SEAL: DAY 05.1 LINE ENDINGS POLICY
**Date:** 2026-01-13
**Author:** Antigravity
**Goal:** Stabilize LF/CRLF handling and eliminate warnings.

## Actions
1. **.gitattributes**: Created with `text=auto` and specific overrides:
   - `*.py`, `*.md`, `*.json`, `*.yaml`, `*.dart`, `*.sh` -> `eol=lf`
   - `*.bat`, `*.ps1` -> `eol=crlf`
2. **Git Config**:
   - `core.autocrlf false`
   - `core.eol lf`
3. **Renormalization**:
   - Executed `git add --renormalize .`
   - Verified clean status (no unexpected deletions).

## Evidence
- `outputs/runtime/day_05_1_lineendings_before.txt`
- `outputs/runtime/day_05_1_lineendings_after.txt`
- `outputs/runtime/day_05_1_gitattributes.txt`

## Verification
- Repository is now strictly enforcing LF for code/docs.
- Windows scripts retain CRLF.
