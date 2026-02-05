# SEAL: D55.16B.10 — WAR ROOM DEFINITIVE ARCHITECTURE DECISION

**Date:** 2026-02-05
**Author:** Antigravity (Agent)
**Status:** SEALED
**Classification:** ARCHITECTURE STRATEGY & FINAL RESTORATION PLAN

## 1. Executive Summary
The War Room's persistent instability (incorrect statuses, ghost 404s, "whack-a-mole" wiring fixes) is caused by a **Fundamental Architecture Mismatch**.
-   **Frontend (V2)** is designed as a **Hyper-Atomic Consumer** (30+ parallel HTTP calls).
-   **Backend (V1)** is designed as a **Unified Aggregator** (`WarRoom.get_dashboard` bundles everything).
-   **Result**: The system is in a "Schizophrenic Hybrid" state, paying the latency logic cost of V2 while ignoring the efficiency of V1, leading to partial failures, race conditions, and duplicated logic.

## 2. Q1: Runtime Request Map (The "Hybrid" Problem)
Observed runtime behavior during War Room load:

| Source | Requests | Behavior | Impact |
| :--- | :--- | :--- | :--- |
| **Frontend** | **29+ Calls** | Atomic fetches (`/misfire`, `/lab/os/iron/status`, etc.) | **High Fragility.** 1 failure = Partial UI Breakage. Excessive Latency. |
| **Backend** | **1 Handler** | `/dashboard` (Aggregates 90% of data) | **Underutilized.** Frontend calls it but ignores most of it (uses it only for "Dashboard" tile). |
| **Canon Radar** | **2 Calls** | `/lab/canon/debt_index` + Static Snapshot | **Disconnected.** Fetched independently of the main snapshot. |

**Verdict**: The Frontend is "Fighting" the Backend. It tries to re-assemble the truth atom-by-atom, instead of accepting the Backend's unified truth.

## 3. Q2: Root Cause
**"Architecture Drift"**:
1.  **Day 19 (Backend)**: `WarRoom.py` was built to be the Single Source of Truth, aggregating all modules into one JSON.
2.  **Day 53 (Frontend)**: `WarRoomRepository.dart` was built to be "Resilient" by fetching atoms in parallel using `Future.wait`.
3.  **Conflict**: The Frontend logic *re-implements* the aggregation logic that already exists in Python, but does so over the network (Latency + Risk) instead of in-memory (Instant + Safe).

## 4. Q3: Definitive Solution
**WE HEREBY MANDATE "OPTION A": UNIFIED SNAPSHOT PROTOCOL (USP).**

### 4.1 The Contract
-   **Single Endpoint**: `/lab/war_room/snapshot` (maps to `WarRoom.get_dashboard`).
-   **Single Payload**: A unified JSON tree containing `osHealth`, `iron`, `misfire`, `autofix`, `housekeeper`, etc.
-   **Single Auth**: One `X-Founder-Key` check gates the entire view.

### 4.2 The Plan (Migration to Day 56)
1.  **Backend (Phase 1)**: Enhance `WarRoom.get_dashboard()` to ensure it returns **100% of the fields** required by `WarRoomSnapshot.dart`. (Currently missing some deep nested fields).
2.  **Frontend (Phase 2)**: Refactor `WarRoomRepository.dart`:
    -   **DELETE** `fetchMisfire()`, `fetchIron()`, `fetchHousekeeper()`, etc.
    -   **CREATE** `fetchUnifiedSnapshot()`: Calls `/lab/war_room/snapshot`.
    -   **UPDATE** `WarRoomSnapshot.fromUnifiedJson(Map json)` constructor.
3.  **Cleanup**: Remove the 29 atomic endpoints from `api_server.py` if they are not used by other tools (e.g. CLI).

## 5. Verification Conditions
The Transformation is complete ONLY when:
1.  **Network Tab**: Shows **1 Request** to `/lab/war_room/snapshot` (plus maybe Debt Radar if kept separate for size).
2.  **Latency**: War Room loads < 500ms (vs current 2-3s).
3.  **Consistency**: "All or Nothing" status. No "Yellow/Red/Green" mismatch due to request races.

## 6. Status
**STRATEGY SEALED.** This document governs the D56 implementation.
## Pending Closure Hook

Resolved Pending Items:
- [ ] (None)

New Pending Items:
- [ ] (None)
