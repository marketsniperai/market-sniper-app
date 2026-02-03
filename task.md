# OPERATION EWIMS-GOLD.V2 - Task List

## Phase 1: Historical Claim Extraction (The Book of Promises)
- [x] Locate and list all source documents (War Calendar, Project State, Seals) <!-- id: 0 -->
- [x] Extract claims from `OMSR_WAR_CALENDAR*` <!-- id: 1 -->
- [x] Extract claims from `PROJECT_STATE.md` <!-- id: 2 -->
- [x] Extract claims from `SEAL_*.md` files (Day 0-50) <!-- id: 3 -->
- [x] Consolidate into `outputs/audits/D50_EWIMS_PROMISES_INDEX.json` <!-- id: 4 -->

## Phase 2: Reality Scan (The Autopsy)
- [x] Verify existence of code/files for each claim <!-- id: 5 -->
- [x] Verify wiring/endpoints for relevant claims <!-- id: 6 -->
- [x] Verify artifacts/UI presence <!-- id: 7 -->
- [x] classify each claim as ALIVE, ZOMBIE, or GHOST <!-- id: 8 -->

## Phase 3: Chronological Truth Matrix
- [x] Generate `outputs/audits/D50_EWIMS_CHRONOLOGICAL_MATRIX.md` <!-- id: 9 -->

## Phase 4: Ghost & Zombie Extraction (The Hit List)
- [x] Generate `outputs/audits/D50_EWIMS_GHOST_ZOMBIE_LIST.md` <!-- id: 10 -->

## Phase 5: Coverage Metrics
- [x] Generate `outputs/audits/D50_EWIMS_COVERAGE_SUMMARY.json` <!-- id: 11 -->

## Phase 6: Verdict
- [x] Generate `outputs/audits/D50_EWIMS_FINAL_VERDICT.md` <!-- id: 12 -->

## Phase 7: D51 Checkpoint & Commit
- [x] Create branch `checkpoint/d51_post_ewims_checkpoint` <!-- id: 13 -->
- [x] Stage and verify file categories (Core vs Artifacts) <!-- id: 14 -->
- [x] Generate `CHECKPOINT_D51_STATUS.md` <!-- id: 15 -->
- [x] Generate `SEAL_CHECKPOINT_D51_GIT.md` <!-- id: 16 -->
- [x] Commit with clean status <!-- id: 17 -->

## Phase 8: Deuda Triage (269 Pending)
- [x] Run Git Status Analysis (Porcelain, Human, Diff, LS) <!-- id: 18 -->
- [x] Analyze Top Offenders & Folder Grouping <!-- id: 19 -->
- [x] Scan for Secrets/Danger Patterns <!-- id: 20 -->
- [x] Generate `PENDING_269_DECISION.md` (Keep/Ignore/Archive/Delete) <!-- id: 21 -->
- [x] Create `SEAL_D51_PENDING_269_TRIAGE.md` <!-- id: 22 -->

## Phase 9: D51 Clean Slate Execution
- [x] Baseline: Checkpoints (Status, Diff, Untracked) <!-- id: 23 -->
- [x] Inventory: Generate `D51_TRIAGE_FINAL.md` with explicit buckets <!-- id: 24 -->
- [x] Apply: Update `.gitignore` (Ignore bucket) <!-- id: 25 -->
- [x] Execute: Move (Archive) and Delete (Temp) <!-- id: 26 -->
- [x] Verify: Post-cleanup Git Status & Smoke Test <!-- id: 27 -->
- [x] Seal: `SEAL_D51_CLEAN_SLATE_TRIAGE.md` & Commit <!-- id: 28 -->

## Phase 10: War Room Redesign Exploration (D52)
- [x] Research: Institutional Dashboard Patterns (Conceptual) <!-- id: 29 -->
- [x] Define: Information Architecture & Zones <!-- id: 30 -->
- [x] Define: Visual Hierarchy & Density Rules <!-- id: 31 -->
- [x] Draft: Layout Variants (Dense vs Overview) <!-- id: 32 -->
- [x] Codify: War Room UX Principles <!-- id: 33 -->
- [x] Artifact: `design/WAR_ROOM_UX_EXPLORATION.md` <!-- id: 34 -->

## Phase 11: War Room V2 Implementation - Variant A (D52)
- [ ] Plan: Refactoring Strategy & Widget Breakout <!-- id: 35 -->
- [ ] Impl: `HoneycombGrid` & `ServiceCell` Widgets (Infrastructure) <!-- id: 36 -->
- [ ] Impl: `AlphaTickerStrip` (Intelligence) <!-- id: 37 -->
- [ ] Impl: `GlobalCommandBar` (Status/Navigation) <!-- id: 38 -->
- [ ] Assemble: `WarRoomV2_FounderLayout` <!-- id: 39 -->
- [ ] Verify: Density Checks & Data Wiring <!-- id: 40 -->
- [ ] Seal: `SEAL_D52_WAR_ROOM_V2.md` <!-- id: 41 -->
