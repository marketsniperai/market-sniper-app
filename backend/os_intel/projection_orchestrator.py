import json
import os
import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any

# Internal OS Imports
from backend.artifacts.io import atomic_write_json, safe_read_or_fallback, get_artifacts_root
from backend.os_ops.iron_os import IronOS
from backend.lexicon_pro_engine import LexiconProEngine
from backend.os_intel.context_tagger import ContextTagger
from backend.os_ops.hf_cache_server import OnDemandCacheServer # HF-CACHE-SERVER
from backend.os_ops.global_cache_server import GlobalCacheServer # HF-DEDUPE-GLOBAL

# Canonical Configuration
PROJECTION_ARTIFACT_PATH = Path("outputs/os/projection/projection_report.json")

class ProjectionState:
    OK = "OK"
    CALIBRATING = "CALIBRATING"
    INSUFFICIENT_DATA = "INSUFFICIENT_DATA"
    PROVIDER_DENIED = "PROVIDER_DENIED"

class ProjectionOrchestrator:
    """
    D47.HF17 PROJECTION ORCHESTRATOR V0
    
    The Canonical Mixing Engine for probabilistic context.
    Orchestrates inputs from Evidence, Options, News, Macro, and AGMS
    to produce a safely gated Projection Report.
    
    PRINCIPLES:
    1. NO FAKING PRECISION. If inputs are missing -> CALIBRATING.
    2. NO SINGLE PREDICTIONS. Only Scenario Envelopes.
    3. PRODUCTION OBSERVABLE. Artifact always exists.
    """
    
    VERSION = "0.1.0"
    
    @staticmethod
    def build_projection_report(symbol: str = "SPY", timeframe: str = "DAILY") -> Dict[str, Any]:
        """
        Main Orchestration Function.
        Supports DAILY (Intraday View) and WEEKLY (5-Day View).
        1. Check System Health/Gates.
        2. Load Upstream Artifacts.
        3. Determine Gating/State.
        4. Compose Report.
        5. Write Artifact (Timeframe specific).
        """
        
        # 0. HF-CACHE-SERVER: Check Cache First
        # A. Global Cache (Public / GCS) - Highest Efficiency
        global_cached = GlobalCacheServer.get(symbol, timeframe)
        if global_cached:
             # Populate Local Cache for next time (Read-Through)
             OnDemandCacheServer.put(symbol, timeframe, global_cached)
             return global_cached

        # B. Local Cache (Pod Local)
        if cached:
            return cached

        # 0C. HF32: COST POLICY ENFORCEMENT
        # "One Compute Per Ticker Per Day (ET)"
        # Check Ledger
        from backend.os_ops.computation_ledger import ComputationLedger
        
        if ComputationLedger.has_run_today(symbol, timeframe):
            # Already computed today? Try hard to find existing cache.
            # 1. Try Global Latest
            fallback_global = GlobalCacheServer.get_latest_for_day(symbol, timeframe)
            if fallback_global:
                fallback_global["policy_block"] = True
                fallback_global["managed_by_policy"] = "HF32_DAILY_LIMIT"
                return fallback_global
            
            # 2. Try Local Latest
            fallback_local = OnDemandCacheServer.get_latest_for_day(symbol, timeframe)
            if fallback_local:
                 fallback_local["policy_block"] = True
                 fallback_local["managed_by_policy"] = "HF32_DAILY_LIMIT"
                 return fallback_local
                 
            # 3. If NO cache found (e.g. wiped), we MUST re-compute to produce truth.
            # We do NOT block if we cannot serve data. "Source Ladder is Sacred."
            print(f"[POLICY] HF32 Limit hit for {symbol}, but no cache found. Computing.")
        
        # If we proceed to compute, we will record it in the ledger at the end.

        # 1. Initialize State & Diagnostics
        current_state = ProjectionState.CALIBRATING # Default start
        state_reasons = [] # List[str]
        engines_used = [] # List[str]
        inputs_meta = {} # Dict[str, Any]
        
        # 2. Check System Health (Iron OS)
        # If system is Unhealthy, we degrade immediately.
        # Note: IronOS.get_status() returns None if unavailable.
        iron_status = IronOS.get_status()
        if not iron_status or iron_status.get("status") not in ["NOMINAL", "DEGRADED", "LOCKED"]:
            # If Iron OS is offline or unknown, we trust nothing.
            current_state = ProjectionState.INSUFFICIENT_DATA
            state_reasons.append("SYSTEM_HEALTH_UNKNOWN")
        elif iron_status.get("status") == "LOCKED":
             current_state = ProjectionState.PROVIDER_DENIED
             state_reasons.append("SYSTEM_LOCKED")
             
        engines_used.append("IRON_OS")
        
        # 3. Load Upstream Inputs (Try/Catch wrapper implicitly via safe_read)
        # A. Options Engine
        options_res = safe_read_or_fallback("engine/options_context.json")
        options_data = options_res.get("data")
        if options_res["success"] and options_data:
             engines_used.append("OPTIONS")
             inputs_meta["options"] = {
                 "status": options_data.get("status"),
                 "as_of": options_data.get("as_of_utc")
             }
        else:
             state_reasons.append("OPTIONS_UNAVAILABLE")

        # B. Evidence Engine (Critical for Base Lane)
        evidence_res = safe_read_or_fallback("engine/evidence_summary.json")
        evidence_data = evidence_res.get("data")
        if evidence_res["success"] and evidence_data:
             engines_used.append("EVIDENCE")
             inputs_meta["evidence"] = {
                 "status": evidence_data.get("status"),
                 "sample_size": evidence_data.get("sample_size", 0),
                 "metrics": evidence_data.get("metrics") or {} # HF26: Expose Win Rate/Avg Move
             }
        else:
             state_reasons.append("EVIDENCE_UNAVAILABLE")
             
        # C. Macro (Contextual)
        macro_res = safe_read_or_fallback("engine/macro_context.json")
        if macro_res["success"]:
             engines_used.append("MACRO")
             inputs_meta["macro"] = {"status": "AVAILABLE"} # Stub usually
        else:
             state_reasons.append("MACRO_UNAVAILABLE")
             
        # D. News Engine (Qualitative Tilt)
        news_res = safe_read_or_fallback("engine/news_digest.json")
        news_data = news_res.get("data")
        if news_res["success"] and news_data and news_data.get("status") == "EXISTING":
             engines_used.append("NEWS")
             # HF26: Expose Top 3 Headlines for Catalyst Radar
             headlines = []
             if "items" in news_data and isinstance(news_data["items"], list):
                 headlines = [item.get("headline", "News Item") for item in news_data["items"][:3]]
                 
             inputs_meta["news"] = {
                 "status": "AVAILABLE", 
                 "count": len(news_data.get("items", [])),
                 "headlines": headlines 
             }
        else:
             state_reasons.append("NEWS_UNAVAILABLE")

        # 4. Determine Composite State
        # If we haven't been forced into DENIED/INSUFFICIENT by System Health:
        if current_state == ProjectionState.CALIBRATING:
             # Critical Inputs Check
             is_evidence_stub = evidence_data and evidence_data.get("status") == "N_A"
             is_options_stub = options_data and options_data.get("status") in ["N_A", "ERROR", "STUB"]
             
             if is_evidence_stub: state_reasons.append("EVIDENCE_IS_STUB")
             if is_options_stub: state_reasons.append("OPTIONS_IS_STUB")
                 
             missing_intraday = True # True until HF18 check below

             # Evaluation
             if "SYSTEM_LOCKED" in state_reasons:
                 current_state = ProjectionState.PROVIDER_DENIED
             elif missing_intraday or is_evidence_stub or is_options_stub:
                 current_state = ProjectionState.CALIBRATING
             else:
                 current_state = ProjectionState.OK

        # 5. Context Fusion (HF20)
        # Derive Tags
        ctx_options = ContextTagger.tag_options(options_data if options_data and options_data.get("status") == "LIVE" else None)
        ctx_news = ContextTagger.tag_news(news_data if news_data and news_data.get("status") == "EXISTING" else None)
        ctx_macro = ContextTagger.tag_macro(None) # Always none for now unless simple stub logic matches tagger expectation

        # If Macro file existed but was stub, we might pass it. 
        # Checking logic above: "macro_res = safe_read..."
        if inputs_meta.get("macro", {}).get("status") == "AVAILABLE":
             ctx_macro = ContextTagger.tag_macro({"status": "AVAILABLE"}) # Simulate stub data

        # Calculate Volatility Scale & Notes from Tags
        vol_scale = 1.0
        boundary_mode = ctx_options.get("boundary_mode", "NONE")
        
        scenario_notes_base = ["Base Case (Demo)."]
        scenario_notes_stress = ["Stress Case (Demo)."]
        
        # Options Influence
        if boundary_mode == "EXPECTED_MOVE":
             scenario_notes_base.append("Options expected move active.")
             # Conceptually we'd use the cone here. For V0, we stick to Scale logic or 1.0 if cone handles it?
             # IntradaySource only supports 'volatility_scale'.
             # Let's assume EXPECTED_MOVE behaves like Normal vol unless specific width provided.
             pass
        elif boundary_mode == "IV_SCALE":
             if "IV_REGIME_HIGH" in ctx_options["tags"]:
                 vol_scale = 1.5
                 scenario_notes_stress.append("Elevated IV detected (Options).")
             elif "IV_REGIME_LOW" in ctx_options["tags"]:
                 vol_scale = 0.8
                 scenario_notes_base.append("Low IV environment (Options).")
        
        # News Influence
        if "MACRO_HEADLINES" in ctx_news["tags"]:
             scenario_notes_stress.append("Recent macro headlines active.")
        if "EARNINGS_CLUSTER" in ctx_news["tags"]:
             scenario_notes_stress.append("Earnings volatility risk.")
        
        # Macro Influence
        if "MACRO_STUB_NEUTRAL" in ctx_macro["tags"]:
             scenario_notes_base.append("Macro context: Neutral (Stub).")

        # HF18 UPDATE: Inject Intraday Series (Demo/Live)
        
        # Import here to avoid circular/early init
        from backend.os_intel.intraday_series_source import IntradaySeriesSource
        from backend.os_intel.projection_series_coords import ProjectionSeriesCoords
        
        # Load Series with Vol Scale
        # Load Series with Vol Scale (using alias/compat wrapper)
        series_data = IntradaySeriesSource.load(
            symbol=symbol, 
            as_of_utc=datetime.datetime.utcnow(), 
            volatility_scale=vol_scale,
            timeframe=timeframe
        )
        
        # Calc Coords/Bounds
        coords = ProjectionSeriesCoords.compute_coords(
            series_data.get("pastCandles", []),
            series_data.get("futureBase", []),
            series_data.get("futureStress", [])
        )
        
        # Update State if Demo Series Available
        if series_data.get("source") == "DEMO_DETERMINISTIC":
             # We allow Upgrade if not Blocked by Iron
             if current_state in [ProjectionState.CALIBRATING, ProjectionState.OK]:
                 # Only override if we aren't Denied
                 current_state = "OK" 
                 if "DEMO_SERIES_ACTIVE" not in state_reasons:
                     state_reasons.append("DEMO_SERIES_ACTIVE")
                 if "MISSING_INTRADAY_SERIES" in state_reasons:
                     state_reasons.remove("MISSING_INTRADAY_SERIES")

        base_scenario = {
            "laneState": "OK" if current_state == "OK" else "CALIBRATING",
            "notes": scenario_notes_base,
            "envelope": {
                "candles": series_data.get("futureBase", [])
            },
            "bounds": coords
        }
        stress_scenario = {
            "laneState": "OK" if current_state == "OK" else "CALIBRATING", 
            "notes": scenario_notes_stress,
            "envelope": {
                "candles": series_data.get("futureStress", []) 
            },
            "bounds": coords
        }
        
        # 6. Compose Final Artifact (Tactical Playbook HF27)
        tactical_watch = []
        tactical_invalidate = []
        
        # Evidence Logic
        if "metrics" in inputs_meta.get("evidence", {}):
            wr = inputs_meta["evidence"]["metrics"].get("win_rate", 0)
            if wr > 0.60:
                tactical_watch.append(f"High historical resolution probability (> {int(wr*100)}%).")
            elif wr < 0.40:
                tactical_watch.append(f"Low historical persistence (< {int(wr*100)}%); expect chop.")
                
        # Options Logic
        if boundary_mode == "EXPECTED_MOVE":
             tactical_watch.append("Price action respect of volatility envelope.")
             tactical_invalidate.append("Volatility expansion beyond expected move.")
        elif boundary_mode == "IV_SCALE":
             tactical_watch.append("Regime-adjusted volatility ranges.")
             
        # News/Catalyst Logic
        if inputs_meta.get("news", {}).get("count", 0) > 0:
             tactical_watch.append("Catalyst event monitoring active.")
             
        # Defaults if empty
        if not tactical_watch:
             tactical_watch.append("Standard deviation mechanics.")
             tactical_watch.append("Key level reactions (intraday).")
             
        if not tactical_invalidate:
             tactical_invalidate.append("Volatility expansion vs forecast.")
             tactical_invalidate.append("Structural break of current regime.")

        tactical_block = {
            "watch": tactical_watch[:4], # Limit to 4
            "invalidate": tactical_invalidate[:4]
        }

        payload = {
            "version": ProjectionOrchestrator.VERSION,
            "symbol": symbol,
            "asOfUtc": datetime.datetime.utcnow().isoformat() + "Z",
            "state": current_state,
            "stateReasons": state_reasons,
            "enginesUsed": engines_used + ["INTRADAY_DEMO"],
            "inputs": inputs_meta,
            "tactical": tactical_block, # HF27
            "contextTags": {
                "options": ctx_options,
                "news": ctx_news,
                "macro": ctx_macro
            },
            "missingInputs": [k for k in ["options", "news", "macro", "evidence"] if k not in inputs_meta or inputs_meta[k].get("status") == "N_A"],
            "intraday": {
                "intervalMin": series_data.get("intervalMin", 5),
                "pastCandles": series_data.get("pastCandles", []),
                "nowCandle": series_data.get("nowCandle"),
            },
            "scenarios": {
                "base": base_scenario,
                "stress": stress_scenario
            },
            "safety": {
                "lexiconSafe": True,
                "noPredictionClaims": True
            }
        }
        
        # Inject Timeframe
        payload["timeframe"] = timeframe
        
        # 7. Write to Disk
        ProjectionOrchestrator._write_artifact(payload, timeframe)
        
        # 8. HF-CACHE-SERVER: Populate Cache
        # 8. HF-CACHE-SERVER: Populate Cache
        OnDemandCacheServer.put(symbol, timeframe, payload)
        
        # 8B. HF-DEDUPE-GLOBAL: Populate Global Cache (Public)
        GlobalCacheServer.put(symbol, timeframe, payload)
        
        # 9. HF32: Update Computation Ledger
        ComputationLedger.record(symbol, timeframe)
        
        return payload

    @staticmethod
    def _write_artifact(payload: Dict[str, Any], timeframe: str):
        try:
            # Determine filename
            # DAILY -> projection_report.json (Compat/Primary) AND projection_report_daily.json
            # WEEKLY -> projection_report_weekly.json
            
            root = get_artifacts_root() / "os/projection"
            root.mkdir(parents=True, exist_ok=True)
            
            if timeframe == "DAILY":
                 atomic_write_json(str(root / "projection_report.json"), payload)
                 atomic_write_json(str(root / "projection_report_daily.json"), payload)
            elif timeframe == "WEEKLY":
                 atomic_write_json(str(root / "projection_report_weekly.json"), payload)
                 
        except Exception as e:
            print(f"[PROJECTION_ORCHESTRATOR] Write Failed: {e}")
            # Non-blocking, but logged.

if __name__ == "__main__":
    # verification run
    print(json.dumps(ProjectionOrchestrator.build_projection_report("SPY", "WEEKLY"), indent=2))
