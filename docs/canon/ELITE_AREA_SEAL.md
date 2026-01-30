# ELITE AREA SEAL (GOVERNANCE DECLARATION)

**Authority:** CANONICAL
**Seal Date:** 2026-01-29
**Scope:** D49 (Elite Subsystem)

## 1. Definition
The **Elite Area** is the institutional intelligence, mentorship, and authority layer of the MarketSniper OS. It acts as the "Cognitive Interface" between the deterministic specialized engines (Iron OS) and the human operator (Founder/Elite User).

## 2. What Elite IS
1.  **Deterministic First:** Elite prioritizes deterministic data (Rituals, State Snapshots, Hard Rules) over generative text.
2.  **The Mentor:** Elite adopts a "Battle Buddy" persona—supportive, disciplined, non-judgmental.
3.  **The Authority:** Elite is the only subsystem allowed to "Explain" complex system states (using `EliteExplainerProtocol`).
4.  **Memory-Aware:** Elite persists longitudinal user context (Reflections) to provide personalized guidance.

## 3. What Elite is NOT
1.  **NOT a Chatbot:** Elite does not engage in open-ended chitchat. It responds to Intents and Rituals.
2.  **NOT a Financial Advisor:** Elite explains *system signals* and *market regimes*, never giving financial advice.
3.  **NOT an Executor:** Elite cannot execute trades or modify system kernel parameters directly (uses `EventRouter` or `AutoFix` bridges).

## 4. Governance Rules
1.  **Ritual Primacy:** Interaction flows are governed by strict Ritual Policies (`os_elite_ritual_policy_v1.json`). If a routine is not in the policy, it does not exist.
2.  **Cost Guard:** All LLM calls must pass through `elite_llm_boundary.py` to enforce cost limits and audit trails.
    -   *Key lives in env only; never stored client-side; Secret Manager recommended.*
3.  **PII Redaction:** No personally identifiable information (PII) is sent to cloud LLMs or stored in cloud ledgers. Local storage is preferred.
4.  **Free Window Protocol:** The "Monday Free Window" (09:20-10:20 ET) is a strict canonical policy. Access availability must match the policy triggers exactly.

## 5. Monetization Boundary
- **Elite Tier:** Full access to all Rituals, infinite Explainer calls, Cloud Memory.
- **Plus Tier:** Limited Rituals, capped Explainer.
- **Free Tier:** Monday Free Window (1h/week) only. "Look but don't touch" elsewhere.

## 6. Safety Guarantees
- **Fallback Safe:** If LLM or API fails, Elite falls back to "CALIBRATING" or deterministic "Offline Mode" responses.
- **Context Isolation:** User memory is isolated. Cross-user learning is strictly bucketed and anonymized.

## 7. Status
**SEALED.** This area is frozen for production. Future updates requires a new D-Day sequence.
