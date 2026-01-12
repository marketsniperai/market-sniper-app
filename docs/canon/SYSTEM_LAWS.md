# SYSTEM LAWS (G0.CANON_1)

**Authority:** SUPREME

## 1. The Law of Truth (N/A > Guessing)
It is better to show **Nothing** (N/A) or an **Error**, than to show a **Guess**.
- The system shall NO LONGER predict without data.
- "Neutral" is a valid state. "Unknown" is a valid state.

## 2. The Law of the Lens
The API Server is a **Lens**, NOT a Brain.
- Logic belongs in the Pipeline.
- The API restricts itself to:
    - Routing
    - Auth
    - Reading JSON
    - Shaping JSON for UI

## 3. The Law of Silence
There shall be **No Silent Failures**.
- If a component fails, it must emit a Trace or a visible Error State.
- Swallow-and-log is BANNED for critical paths.

## 4. The Law of Roots
There is **One** Artifacts Root.
- `backend/outputs/`.
- No stray files in `tmp/` or root.

## 5. The Law of Precedence
1. **Safety** overrides **Performance**.
2. **Truth** overrides **Stability**.
3. **Founder Override** overrides **Everything** (Forensics).
^>
**RULE:**
Glossary
is
the
semantic
authority:
when
in
doubt
follow
GLOSSARY.
