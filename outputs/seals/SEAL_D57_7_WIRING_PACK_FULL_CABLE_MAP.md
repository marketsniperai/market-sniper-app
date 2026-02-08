# SEAL_D57_7_WIRING_PACK_FULL_CABLE_MAP

## 1. Context
- **Date:** 2026-02-05
- **Task:** D57.7 Wiring Pack Generation
- **Objective:** Create a consolidated "Wiring Pack" for NotebookLM ingestion, documenting all OS connectivity.

## 2. Capabilities
- **Script:** `tools/ewimsc/wiring_pack/generate_wiring_pack.py`
- **Logic:**
  - Imports `backend.api_server` to enumerate endpoints.
  - Integrates with `zombie_report.json` for classification.
  - Scans codebase for Prod URLs, Buckets, and Pipeline triggers.
- **Outputs:**
  - `outputs/proofs/D57_7_WIRING_PACK/WIRING_PACK.md` (Human Readable)
  - `outputs/proofs/D57_7_WIRING_PACK/WIRING_PACK.json` (Machine Readable)
  - `outputs/proofs/D57_7_WIRING_PACK/WIRING_PACK_NOTEBOOKLM.txt` (AI Optimized)

## 3. Findings (Snapshot)
- **Local URL:** `http://127.0.0.1:8787`
- **Prod URL:** `https://marketsniper-api-3ygzdvszba-uc.a.run.app`
- **Total Routes:** 120
- **Classification:**
  - `PUBLIC_PRODUCT`: 14
  - `LAB_INTERNAL`: 30
  - `DEPRECATED_ALIAS`: 5
  - `UNKNOWN_ZOMBIE`: 71 (Routes requiring triage/classification)

## 4. Verification
- **Command:** `py tools/ewimsc/wiring_pack/generate_wiring_pack.py`
- **Result:** SUCCESS. Artifacts generated.

## 5. NotebookLM Instructions
1. Upload `WIRING_PACK_NOTEBOOKLM.txt` to your Notebook source list.
2. Ask: "What is the production base URL?"
3. Ask: "List all LAB_INTERNAL endpoints."

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
