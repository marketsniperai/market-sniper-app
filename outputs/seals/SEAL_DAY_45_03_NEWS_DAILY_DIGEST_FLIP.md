# SEAL: DAY 45.03 — NEWS DIGEST (TOP 8) + FLIP

## SUMMARY
Implemented the institutional News Tab surface featuring a "Daily Digest" with compact, flippable cards.
- **Source Ladder**: Prepared to support PIPELINE/CACHE/OFFLINE. Currently initializes to OFFLINE (degraded safely) until pipeline ingestion is active.
- **View Model**: Bounded `NewsDigestItem` with strict limits (Brief 200 chars, Expand 600 chars).
- **Interaction**: Flip interaction (Front: Summary / Back: Expand) managed via local state.
- **Values**: Top 8 limit enforced by design semantics.

## ARTIFACTS
- `lib/models/news/news_digest_model.dart` [NEW]
- `lib/widgets/news_digest_card.dart` [NEW]
- `lib/screens/news_screen.dart` [NEW]
- `lib/layout/main_layout.dart` [MODIFIED]
- `outputs/proofs/day_45/ui_news_daily_digest_proof.json` [NEW]

## VERIFICATION
- **Degradation**: Verified screen defaults to "OFFLINE - System is offline" when no data.
- **Hygiene**: Header displays Freshness/Source/As-Of.
- **Discipline**: Passed `verify_project_discipline.py`.

## STATUS
**SEALED** (Ready for Ingest)
