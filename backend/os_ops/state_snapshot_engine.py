
import json
import os
from datetime import datetime, timedelta
from typing import Dict, Any, List

# Imports
from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback, atomic_write_json
from backend.os_ops.event_router import EventRouter

class StateSnapshotEngine:
    """
    D49.OS.STATE_SNAPSHOT_V1: Institutional State Snapshot Engine.
    Generates a deterministic view of System Mode, Freshness, Providers, and Locks.
    Consumed by Elite to ensure it never speaks out of turn.
    """
    
    ARTIFACT_PATH = "os/state_snapshot.json"
    
    @staticmethod
    def generate_snapshot() -> Dict[str, Any]:
        """
        Generates the snapshot and persists it to disk.
        Returns the snapshot dict.
        """
        snapshot = {
            "timestamp_utc": datetime.utcnow().isoformat() + "Z",
            "system_mode": StateSnapshotEngine._determine_system_mode(),
            "freshness": StateSnapshotEngine._check_freshness(),
            "providers": StateSnapshotEngine._check_providers(),
            "locks": StateSnapshotEngine._get_active_locks(),
            "recent_events": StateSnapshotEngine._get_recent_events()
        }
        
        # Persist
        root = get_artifacts_root()
        path = root / StateSnapshotEngine.ARTIFACT_PATH
        path.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_json(str(path), snapshot)
        
        # V4.1 Update: Generate Full System State (Side-effect)
        try:
            StateSnapshotEngine.generate_system_state()
        except Exception as e:
            # Non-blocking failure for legacy compatibility
            print(f"WARNING: System State Generation Failed: {e}")

        return snapshot

    @staticmethod
    def _determine_system_mode() -> str:
        """
        LIVE | SAFE | CALIBRATING
        Checks for global lock files.
        """
        root = get_artifacts_root()
        
        if (root / "os/locks/CALIBRATION.lock").exists():
            return "CALIBRATING"
        
        if (root / "os/locks/SAFETY.lock").exists():
            return "SAFE"
            
        return "LIVE"

    @staticmethod
    def _check_freshness() -> Dict[str, str]:
        """
        Checks artifact ages against thresholds.
        Dashboard: < 5 mins = FRESH, else STALE.
        OnDemand: Check cache directory modification time? Or just default to FRESH for now.
        """
        freshness = {
            "dashboard": "STALE",
            "on_demand": "FRESH" # logic pending D49.05 refinement
        }
        
        # Dashboard Freshness
        root = get_artifacts_root()
        dash_path = root / "full/dashboard_market_sniper.json"
        
        if dash_path.exists():
            mtime = datetime.fromtimestamp(dash_path.stat().st_mtime)
            age = datetime.now() - mtime
            if age < timedelta(minutes=5):
                freshness["dashboard"] = "FRESH"
        
        return freshness

    @staticmethod
    def _check_providers() -> Dict[str, str]:
        """
        Reads provider_health.json (written by DataMux).
        """
        root = get_artifacts_root()
        path = root / "os/engine/provider_health.json"
        
        providers = {
            "market": "UNKNOWN",
            "options": "UNKNOWN",
            "news": "UNKNOWN"
        }
        
        if path.exists():
            try:
                with open(path, "r") as f:
                    health = json.load(f)
                    
                # Map providers to simple status
                # Logic: If denied -> DENIED. If last success < 1h -> LIVE. Else OFFLINE.
                # Demo is usually LIVE or DEMO.
                
                for key in ["market", "options", "news"]:
                    # Map generic keys to specific provider entries if needed
                    # For now assume direct mapping or 'demo' fallback
                    p_entry = health.get(key) or health.get("demo")
                    
                    if p_entry:
                        if p_entry.get("denied"):
                            providers[key] = "DENIED"
                        elif p_entry.get("last_success_utc"):
                            # Check age? For now just LIVE if success recorded
                            providers[key] = "LIVE"
                        else:
                            providers[key] = "OFFLINE"
                    else:
                        providers[key] = "LIVE" # Default to avoid panic in V1 if no health data yet
            except:
                pass
                
        return providers


    # --- PHASE B: SYSTEM STATE COMPOSER (V4.1) ---
    
    SYSTEM_STATE_PATH = "full/system_state.json"
    
    # Canonical 89-Module Schema (Source: SEAL_SNAPSHOT_100_PERCENT_MODULE_COVERAGE_STATE_MAPPING)
    SYSTEM_STATE_SCHEMA = {
      "ops": {
        "OS.Infra.LayoutPolice": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Runtime Layout Guard." },
        "OS.Ops.Pipeline": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Orchestrates data generation pipelines." },
        "OS.Ops.Misfire": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Detects missed schedules and triggers auto-heal." },
        "OS.Ops.AutoFix": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Recommends and executes recovery actions." },
        "OS.Ops.Housekeeper": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Hygiene Engine (Wired/Manual)." },
        "OS.Ops.Iron": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "State Management, Replay, and History Engine." },
        "OS.Ops.Replay": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Time Machine for Operational States." },
        "OS.Ops.Rollback": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Founder Intent Ledger for State Rollbacks." },
        "OS.Ops.WarRoom": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Unified command center (V2 Refactor)." },
        "OS.Ops.ImmuneSystem": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Active defense against poisoned inputs." },
        "OS.Ops.BlackBox": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Forensic Indestructibility & Truth Recorder." },
        "OS.Ops.ShadowRepair": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Proposes Patches and Executes Runtime Surgery." },
        "OS.Ops.TuningGate": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Governance for Runtime Tuning (2-Vote)." },
        "OS.Ops.ReliabilityLedgerGlobal": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Append-only record of projections." },
        "OS.Ops.ReliabilityReconciler": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Closes the loop with realized outcomes." },
        "OS.Ops.KnowledgeIndex": { "status": "STATIC", "source": "artifact", "observable": True, "notes": "SSOT of all OS modules." },
        "OS.Ops.CalibrationReport": { "status": "STATIC", "source": "artifact", "observable": True, "notes": "Generates accuracy artifacts." },
        "OS.Ops.StateSnapshot": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Real-time system health for Elite (V3)." },
        "OS.Ops.EventRouter": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Central System Event Bus." },
        "OS.Ops.Voice": { "status": "SHADOW", "source": "runtime", "observable": True, "notes": "Governance stub for future Voice Engine." },
        "OS.Logic.Ritual": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Local notification triggers." },
        "OS.OnDemand.Ledger": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Daily Cost Policy Enforcer." }
      },
      "intel": {
        "OS.Intel.Foundation": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Memory, Truth Mirror, and Base Truth." },
        "OS.Intel.Intel": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Pattern recognition and coherence analysis." },
        "OS.Intel.Dojo": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Offline Simulation & Deep Dreaming." },
        "OS.Intel.ShadowRec": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Maps patterns to Shadow Playbooks." },
        "OS.Intel.Handoff": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Secure bridge from Thinker to Actor." },
        "OS.Intel.Thresholds": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Self-tuning sensitivity based on market state." },
        "OS.Intel.Bands": { "status": "STATIC", "source": "artifact", "observable": True, "notes": "Standardizes confidence levels." },
        "OS.Intel.Options": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Descriptive IV/Skew/Move context (N/A Safe)." },
        "OS.Intel.Macro": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Rates/USD/Oil context + degradation." },
        "OS.Intel.Evidence": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Regime matching + Sample Size guard." },
        "OS.Intel.Projection": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Central mixing engine (Fusion)." },
        "OS.Intel.News": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Unified News Truth (Source Ladder)." },
        "OS.Intel.Calendar": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "High-Impact Event Schedule." },
        "OS.Intel.Attribution": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "\"Show Work\" Logic for Projections." },
        "OS.Intel.IntradaySeries": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Deterministic 5m candle generator." },
        "OS.Intel.ContextTagger": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Semantic tagging for inputs." },
        "OS.Intel.RitualRouter": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Router for ritual artifacts." },
        "OS.Intel.ChatCore": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Hybrid Chat + Tool Router." },
        "OS.Intel.UserMemory": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Longitudinal user reflection." },
        "OS.Intel.LLMBoundary": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Safe LLM wrapper with cost/PII guards." }
      },
      "data": {
        "OS.Data.DataMux": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Multi-Provider Failover Layer." },
        "OS.OnDemand.Cache": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Universe-agnostic analysis cache." },
        "OS.OnDemand.Global": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Shared dossier deduplication (Public)." },
        "OS.OnDemand.Recent": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Local offline snapshot persistence." },
        "OS.Data.Provider.AlphaVantage": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Batch-Only Provider Integration." },
        "OS.Logic.WatchlistStore": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Local persistence for tickers." }
      },
      "infra": {
        "OS.Infra.API": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Entry point for all system interactions." },
        "OS.Infra.CloudRun": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Core Compute (Procfile + Lab Probes)." },
        "OS.Infra.LB": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "HTTPS termination + Serverless NEG." },
        "OS.Infra.Hosting": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Static Assets + Rewrite Layer." }
      },
      "ui": {
        "UI.Layout.DashboardComposer": { "status": "STATIC", "source": "static", "observable": False, "notes": "Dashboard Widget Orchestrator." },
        "UI.Component.DashboardCard": { "status": "STATIC", "source": "static", "observable": False, "notes": "Canonical Card Wrapper." },
        "UI.WarRoom.Shell": { "status": "STATIC", "source": "static", "observable": False, "notes": "Institutional Command Center Shell." },
        "OS.UI.UniverseScreen": { "status": "STATIC", "source": "static", "observable": False, "notes": "Core Universe Management." },
        "OS.UI.OnDemandPanel": { "status": "STATIC", "source": "static", "observable": False, "notes": "Ticker search and analysis surface." },
        "OS.UI.WatchlistScreen": { "status": "STATIC", "source": "static", "observable": False, "notes": "Persistent watchlist management." },
        "OS.UI.NewsTab": { "status": "STATIC", "source": "static", "observable": False, "notes": "Flip-card daily digest surface." },
        "OS.UI.CalendarTab": { "status": "STATIC", "source": "static", "observable": False, "notes": "Impact-rated event schedule." },
        "OS.UI.PremiumMatrix": { "status": "STATIC", "source": "static", "observable": True, "notes": "Feature comparison and upgrade." },
        "OS.UI.ShareSheet": { "status": "STATIC", "source": "static", "observable": False, "notes": "Watermarked image export." },
        "OS.UI.CommandCenter": { "status": "STATIC", "source": "static", "observable": False, "notes": "Elite-only mystery surface." },
        "OS.UI.CoherenceQuartet": { "status": "STATIC", "source": "static", "observable": False, "notes": "Premium Anchor (4-Quadrant)." },
        "OS.UI.RegimeSentinel": { "status": "STATIC", "source": "static", "observable": False, "notes": "Index Detail Widget (Skeleton)." },
        "UI.Synthesis.Global": { "status": "STATIC", "source": "static", "observable": False, "notes": "Risk State/Driver Synthesis." },
        "OS.UI.SectorSentinel": { "status": "STATIC", "source": "static", "observable": False, "notes": "Real-Time Sector Strip." },
        "OS.UI.TimeTraveller": { "status": "STATIC", "source": "static", "observable": False, "notes": "Interactive H/L/C Chart." },
        "OS.UI.ReliabilityMeter": { "status": "STATIC", "source": "static", "observable": False, "notes": "Real-time Accuracy/Uptime visuals." },
        "OS.UI.TacticalPlaybook": { "status": "STATIC", "source": "static", "observable": False, "notes": "AI Strategy & Setup visualization." },
        "OS.UI.IntelCards": { "status": "STATIC", "source": "static", "observable": False, "notes": "Carousel of synthesis briefings." },
        "OS.UI.MicroBriefing": { "status": "STATIC", "source": "static", "observable": False, "notes": "Briefing content widget." },
        "OS.Elite.ShellV2": { "status": "STATIC", "source": "static", "observable": False, "notes": "Glass Ritual Panel Overlay (70%)." },
        "OS.Elite.Overlay": { "status": "STATIC", "source": "static", "observable": False, "notes": "70/30 Context Shell (Base)." },
        "OS.Elite.RitualGrid": { "status": "STATIC", "source": "static", "observable": False, "notes": "2x3 Ritual Selection Grid." },
        "OS.Elite.BadgeController": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Notification Badge Logic." },
        "OS.Logic.TabState": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Bottom nav persistence." }
      },
      "security": {
        "OS.Infra.Gates": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Enforces system safety and data freshness." },
        "OS.Logic.RitualPolicy": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Windows + Countdown Logic." },
        "OS.Logic.FreeWindow": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Monday Free Window Tracking." },
        "OS.OnDemand.Resolver": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Founder/Elite/Plus/Free Resolution." },
        "OS.Security.EliteGate": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Fail-closed cost/write protection." }
      },
      "contract": {
        "OS.Biz.Dashboard": { "status": "STATIC", "source": "static", "observable": True, "notes": "Main user interface data payload." },
        "OS.Biz.Context": { "status": "STATIC", "source": "static", "observable": True, "notes": "Narrative context and market status." },
        "OS.Domain.Universe": { "status": "STATIC", "source": "static", "observable": True, "notes": "`Core20` Definitions." },
        "OS.Contract.WarRoom": { "status": "STATIC", "source": "static", "observable": True, "notes": "SSOT for Required Keys (Hydration)." }
      },
      "tooling": {
        "Tool.Verifier.Discipline": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Enforces detailed canonical rules." },
        "Tool.Verifier.Schema": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Enforces strict JSON contracts." },
        "Tool.Verifier.Dashboard": { "status": "LIVE", "source": "runtime", "observable": True, "notes": "Enforces dashboard specific layout rules." }
      }
    }
    
    @staticmethod
    def generate_system_state() -> Dict[str, Any]:
        """
        Generates the FULL 89-Module System State (V4.1).
        Path: outputs/full/system_state.json
        """
        root = get_artifacts_root()
        
        # 1. Base Metadata
        system_state = {
            "meta": {
                "generated_at_utc": datetime.utcnow().isoformat() + "Z",
                "run_id": "UNKNOWN", # Standardize to UNKNOWN unless run_manifest is read
                "module_count": 89,
                "api_revision": os.getenv("K_REVISION", "UNKNOWN"),
                "commit_hash": os.getenv("COMMIT_SHA", "UNKNOWN")
            }
        }
        
        # Try to read run_manifest for run_id
        try:
            manifest = safe_read_or_fallback("full/run_manifest.json")
            if manifest["success"]:
                system_state["meta"]["run_id"] = manifest["data"].get("run_id", "UNKNOWN")
        except:
            pass

        # 2. Iterate Schema and Fill
        for section, modules in StateSnapshotEngine.SYSTEM_STATE_SCHEMA.items():
            system_state[section] = {}
            for module_id, spec in modules.items():
                
                # Default from spec
                entry = {
                    "status": spec["status"],
                    "source": spec["source"],
                    "observable": spec["observable"],
                    "last_update": None,
                    "reason": None,
                    "notes": spec["notes"]
                }
                
                # 3. Resolve Runtime State (Minimal Evidence Check)
                if spec["source"] == "runtime":
                    resolved = StateSnapshotEngine._resolve_module_state(module_id)
                    entry.update(resolved)
                
                system_state[section][module_id] = entry

        # 4. Persist
        path = root / StateSnapshotEngine.SYSTEM_STATE_PATH
        path.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_json(str(path), system_state)
        
        return system_state

    @staticmethod
    def _resolve_module_state(module_id: str) -> Dict[str, Any]:
        """
        Reads local artifacts to confirm state.
        Default: UNKNOWN if no evidence found.
        """
        root = get_artifacts_root()
        
        # Common pattern: Check artifact existence
        
        if module_id == "OS.Ops.StateSnapshot":
            # Self-reference
            return {"status": "LIVE", "last_update": datetime.utcnow().isoformat()}

        if module_id == "OS.Ops.Misfire":
            # D62: Deep Embed of Diagnostics
            res = safe_read_or_fallback("full/misfire_report.json")
            if not res["success"]:
                 res = safe_read_or_fallback("misfire_report.json")
            
            if res["success"]:
                data = res["data"]
                return {
                    "status": data.get("status", "UNKNOWN"),
                    "last_update": data.get("timestamp_utc"),
                    "reason": data.get("reason", "OK"),
                    "meta": {
                        "diagnostics": data.get("diagnostics", {
                            "status": "UNAVAILABLE", 
                            "reason": "MISSING_BLOCK"
                        })
                    }
                }

        # Extended Hardening Map (D62.XX)
        # Maps Module ID to list of possible artifact paths (relative to ARTIFACTS_ROOT)
        # First match wins.
        evidence_map = {
            # OPS
            "OS.Ops.Pipeline": ["full/run_manifest.json", "light/run_manifest.json"],
            "OS.Ops.Misfire": ["full/misfire_report.json", "misfire_report.json"],
            "OS.Ops.Housekeeper": ["os/os_findings.json", "os/housekeeper_scan.json", "runtime/housekeeper/housekeeper_scan.json"],
            "OS.Ops.Iron": ["os/os_state.json", "os/os_findings.json", "os/os_coverage.json"],
            "OS.Ops.ImmuneSystem": ["runtime/immune/immune_snapshot.json", "runtime/immune/immune_ledger.jsonl"],
            "OS.Ops.BlackBox": ["runtime/black_box/decision_ledger.jsonl"],
            "OS.Ops.AutoFix": ["runtime/autofix/autofix_status.json"],
            
            # DATA
            "OS.Data.Provider.AlphaVantage": ["full/providers/alpha_vantage_snapshot.json", "providers/alpha_vantage_snapshot.json"],
            "OS.Data.DataMux": ["os/engine/provider_health.json"],
            
            # INTEL
            "OS.Intel.News": ["full/news_digest.json", "news_digest.json", "os/engine/provider_health.json"],
            "OS.Intel.Options": ["engine/options_context.json", "options_report.json", "os/engine/provider_health.json"],
            
            # INFRA (Probes)
            "OS.Infra.API": ["full/run_manifest.json"], # If pipeline runs, API code is detectable
        }

        paths = evidence_map.get(module_id)
        if paths:
            for p in paths:
                path = root / p
                if path.exists():
                     return {
                         "status": "LIVE",
                         "last_update": datetime.fromtimestamp(path.stat().st_mtime).isoformat(),
                         "reason": f"Evidence: {p}"
                     }
            return {"status": "UNKNOWN", "reason": "No Artifact Evidence"}

        # Default for other runtime modules without specific artifact map yet
        # We DO NOT guess LIVE.
        return {"status": "UNKNOWN", "reason": "No Evidence"}


    @staticmethod
    def _get_active_locks() -> List[Dict[str, str]]:
        """
        Reads os_lock.json (Housekeeper/Safety).
        """
        locks = []
        res = safe_read_or_fallback("os_lock.json")
        if res["success"]:
            data = res["data"]
            # Structure depends on lock file schema. Assuming list of locks or singular.
            # If singular:
            if data.get("is_locked"):
                locks.append({
                    "type": data.get("lock_type", "UNKNOWN"),
                    "reason": data.get("reason", "Unknown")
                })
        return locks

    @staticmethod
    def _get_recent_events() -> List[Dict[str, Any]]:
        """
        Tails EventRouter.
        """
        try:
            return EventRouter.get_latest(limit=5)
        except:
            return []
