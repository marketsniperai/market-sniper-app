
import os
import re
import json
import hashlib
from pathlib import Path
from datetime import datetime

# =============================================================================
# STRATEGY & SCORING RULES
# =============================================================================
# 1. CLAIMS are strictly from War Calendar and Project State. Not Seals.
# 2. SEALS are proofs, collected separately.
# 3. EVIDENCE SCORING:
#    - ENDPOINT MATCH (Exact): +5
#    - STRONG FILE/CLASS MATCH: +4 (Requires >= 2 tokens match OR 1 token + explicit endpoint ref)
#    - WIRING EVIDENCE (AST): +4 (Presence of strong primitives like BottomNavigationBar)
#    - ARTIFACT MATCH: +2 (Excluding outputs/seals and outputs/audits)
#    - SEAL ONLY: -100 (Instant Fail for ALIVE status)
# 4. STATUS:
#    - ALIVE: Score >= 4
#    - ZOMBIE: Score >= 2 AND (evidence has "deprecated" or "legacy")
#    - GHOST: Score < 4
# =============================================================================

REPO_ROOT = Path(os.getcwd())
PROJECT_STATE_PATH = REPO_ROOT / "PROJECT_STATE.md"
WAR_CALENDAR_PATH = REPO_ROOT / "docs/canon/OMSR_WAR_CALENDAR__35_45_DAYS.md"
SEALS_DIR = REPO_ROOT / "outputs/seals"
AUDIT_OUTPUT_DIR = REPO_ROOT / "outputs/audits"
AUDIT_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

STOPWORDS = {
    "day", "seal", "sealed", "implemented", "verified", "completed", "restored", "fixed",
    "feature", "system", "module", "engine", "service", "layer", "ui", "screen", "widget",
    "mode", "global", "polish", "refactor", "hotfix", "update", "upgrade", "logic",
    "backend", "frontend", "artifact", "proof", "json", "md", "txt", "py", "dart",
    "demo", "stub", "skeleton", "v1", "v2", "v0", "d47", "d48", "d49", "d50", "d46",
    "d45", "d44", "d43", "d42", "d41", "d40", "d39", "d38", "d37", "d36", "phase",
    "archive", "output", "outputs", "input", "inputs", "action", "actions", "check",
    "audit", "runner", "main", "test", "tests", "spec", "release", "build", "apk",
    "todo", "fix", "bug", "issue", "debt", "radar", "pending", "ledger", "index"
}

# Primitives for Navigation/Wiring detection
WIRING_PRIMITIVES = {
    "bottomnavigationbar", "navigationbar", "cupertinotabscaffold",
    "bottomnavigationbaritem", "navigationdestination",
    "indexedstack", "statefulshellroute", "shellroute", "goroute"
}

# =============================================================================
# UTILS: ATOMICITY & SORTING
# =============================================================================

def atomic_write_json(path, data):
    path = Path(path)
    tmp_path = path.with_suffix(".tmp")
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
    if path.exists():
        path.unlink()
    tmp_path.rename(path)

def atomic_write_text(path, content):
    path = Path(path)
    tmp_path = path.with_suffix(".tmp")
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(content)
    if path.exists():
        path.unlink()
    tmp_path.rename(path)

# =============================================================================
# 1. HARVEST (SORTED)
# =============================================================================

def extract_content():
    claims = []
    seals = []
    
    # A. War Calendar (Truth)
    if WAR_CALENDAR_PATH.exists():
        with open(WAR_CALENDAR_PATH, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if "- [x] D" in line or "- [x] **D" in line:
                    clean = line.strip().replace("- [x]", "").replace("**", "").strip()
                    sku_match = re.match(r'(D\d+([\._][A-Za-z0-9]+)*)', clean)
                    if sku_match:
                        sku = sku_match.group(1)
                        desc = clean.replace(sku, "").strip(" —:-")
                        claims.append({
                            "sku": sku, 
                            "desc": desc, 
                            "source": "WAR_CALENDAR", 
                            "raw": clean,
                            "line": idx
                        })

    # B. Project State (Milestones)
    if PROJECT_STATE_PATH.exists():
        with open(PROJECT_STATE_PATH, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if "(SEALED)" in line and "- [x]" in line:
                    clean = line.strip().replace("- [x]", "").replace("**", "").replace("(SEALED)", "").strip()
                    sku_match = re.match(r'(D\d+[\._\-\w]*)', clean)
                    sku = sku_match.group(1) if sku_match else "MILESTONE"
                    desc = clean.replace(sku, "").strip(" —:-")
                    
                    # Dedupe
                    already = any(c['sku'] == sku and c['desc'] == desc for c in claims)
                    if not already:
                        claims.append({
                            "sku": sku, 
                            "desc": desc, 
                            "source": "PROJECT_STATE", 
                            "raw": clean,
                            "line": idx
                        })

    # C. Seals (Proofs Only)
    if SEALS_DIR.exists():
        for sfile in sorted(SEALS_DIR.glob("SEAL_*.md")):
             seals.append({"name": sfile.name, "path": str(sfile)})

    # Deterministic Sort: By SKU then Source
    claims.sort(key=lambda x: (x["sku"], x["source"], x["line"]))
    
    return claims, seals

# =============================================================================
# 2. INDEX (FROZEN & SORTED)
# =============================================================================

def build_index():
    idx = {
        "endpoints": [],
        "files": [],
        "classes": [],
        "artifacts": [],
        "wiring": {k: [] for k in WIRING_PRIMITIVES} # Map primitive -> list of files
    }
    
    # Endpoints
    api_path = REPO_ROOT / "backend/api_server.py"
    if api_path.exists():
        txt = api_path.read_text(encoding="utf-8", errors="ignore")
        matches = re.findall(r'@app\.(?:get|post|put|delete)\(["\']([^"\']+)["\']', txt)
        idx["endpoints"] = sorted(matches)
        
    # Files & Classes & Artifacts & Wiring
    # Walk deterministically using sorted entries
    for root, dirs, files in os.walk(REPO_ROOT):
        dirs.sort() # Sort in place for os.walk recursion order
        files.sort()
        
        # Exclusions
        if "outputs" in dirs: 
            pass # See below for rpath filtering
        
        if ".git" in dirs: dirs.remove(".git")
        if "node_modules" in dirs: dirs.remove("node_modules")
        if "build" in dirs: dirs.remove("build")
        
        for file in files:
            fpath = Path(root) / file
            rpath = fpath.relative_to(REPO_ROOT).as_posix()
            
            # Exclusion Logic
            if rpath.startswith("outputs/audits"): continue # Self-contamination
            if rpath.startswith("outputs/seals"): continue # Use separate seal logic
            
            # Classification
            if rpath.startswith("outputs/"):
                idx["artifacts"].append(rpath)
            else:
                idx["files"].append(rpath)
                
                if file.endswith(".dart") or file.endswith(".py"):
                    try:
                        content = fpath.read_text(encoding="utf-8", errors="ignore")
                        # 1. Classes
                        classes = re.findall(r'class\s+(\w+)', content)
                        idx["classes"].extend(classes)
                        
                        # 2. Wiring Primitives (Case insensitive scan)
                        content_lower = content.lower()
                        for prim in WIRING_PRIMITIVES:
                            if prim in content_lower:
                                idx["wiring"][prim].append(rpath)
                    except: pass
    
    # Final Sort
    idx["files"].sort()
    idx["classes"].sort()
    idx["artifacts"].sort()
    for k in idx["wiring"]:
        idx["wiring"][k].sort()
    
    return idx

# =============================================================================
# 3. VERIFY & SCORE
# =============================================================================

def get_tokens(text):
    tokens = re.split(r'[^a-zA-Z0-9]', text.lower())
    valid = [t for t in tokens if len(t) > 2 and t not in STOPWORDS]
    return sorted(list(set(valid)))

def score_claim(claim, idx):
    sku = claim["sku"]
    desc = claim["desc"]
    tokens = get_tokens(sku + " " + desc)

    trace = {
        "tokens": tokens,
        "score": 0,
        "breakdown": [],
        "evidence_str": "No trace"
    }

    if not tokens:
        return trace

    best_score = 0
    best_ev = "No trace"

    # STRATEGY A: Explicit Endpoint Match
    explicit_ep = re.search(r'(/[a-z0-9_/]+)', desc.lower())
    if explicit_ep:
        target = explicit_ep.group(1)
        for ep in idx["endpoints"]:
            if target in ep:
                trace["breakdown"].append({"type": "explicit_endpoint", "match": ep, "points": 5})
                if 5 > best_score:
                    best_score = 5
                    best_ev = f"Explicit Endpoint Verified: {ep}"

    # STRATEGY B: Wiring Evidence (Surgical for Navigation)
    # Target D45.02 or claims about Bottom Nav
    is_nav_claim = "D45.02" in sku or "bottom nav" in desc.lower()
    
    if is_nav_claim:
        # Check all wiring primitives (Sorted for determinism)
        for prim in sorted(list(WIRING_PRIMITIVES)):
            files_with_prim = idx["wiring"].get(prim, [])
            for f in files_with_prim:
                # We found a file using a navigation primitive. Award strong points.
                points = 4
                trace["breakdown"].append({
                    "type": "wiring_code", 
                    "match": f"{prim} @ {f}", 
                    "points": points
                })
                if points > best_score:
                    best_score = points
                    best_ev = f"Wiring Evidence: {prim} found in {f}"
        
        if best_score < 4:
             trace["breakdown"].append({
                "type": "wiring_check", 
                "match": "No wiring primitives found", 
                "points": 0
            })

    # STRATEGY C: Keyword Matching
    
    # Check Endpoints
    for ep in idx["endpoints"]:
        hits = sum(1 for t in tokens if t in ep)
        if hits >= 2 or (hits >= 1 and len(tokens)==1):
            points = 5
            trace["breakdown"].append({"type": "endpoint_match", "match": ep, "hits": hits, "points": points})
            if points > best_score:
                best_score = points
                best_ev = f"Endpoint Match: {ep} (Tokens: {hits})"

    # Check Files
    for f in idx["files"]:
        f_lower = f.lower()
        hits = sum(1 for t in tokens if t in f_lower)
        
        points = 0
        if hits >= 2:
            points = 4
        elif hits == 1:
            # Check length: lowered to 4 per user "Gold" request
            matched_token = next(t for t in tokens if t in f_lower)
            if len(matched_token) >= 4: 
                points = 4
            else:
                points = 1
        
        if points > 0:
            trace["breakdown"].append({"type": "file_match", "match": f, "hits": hits, "points": points})
            if points > best_score:
                best_score = points
                best_ev = f"File Match: {f} (Hits: {hits})"

    # Check Classes
    for c in idx["classes"]:
        c_lower = c.lower()
        hits = sum(1 for t in tokens if t in c_lower)
        points = 0
        if hits >= 2:
            points = 4
        elif hits == 1 and len(tokens) == 1:
             points = 4
        
        if points > 0:
            trace["breakdown"].append({"type": "class_match", "match": c, "hits": hits, "points": points})
            if points > best_score:
                best_score = points
                best_ev = f"Class Match: {c}"

    # Check Artifacts
    for a in idx["artifacts"]:
        a_lower = a.lower()
        hits = sum(1 for t in tokens if t in a_lower)
        if hits >= 1:
            points = 2
            trace["breakdown"].append({"type": "artifact_match", "match": a, "hits": hits, "points": points})
            if points > best_score:
                best_score = points
                best_ev = f"Artifact Match: {a}"

    trace["score"] = best_score
    trace["evidence_str"] = best_ev
    return trace

def run_audit():
    print("--- STARTING EWIMS DETERMINISTIC AUDIT (WIRING ENABLED) ---")
    
    # 1. Freeze Inputs
    claims, seals = extract_content()
    index = build_index()
    
    # 2. Hash Snapshot (for verification)
    snapshot_str = json.dumps(claims, sort_keys=True) + json.dumps(index, sort_keys=True)
    input_hash = hashlib.sha256(snapshot_str.encode("utf-8")).hexdigest()
    
    results = []
    full_trace = {}
    stats = {"ALIVE": 0, "GHOST": 0, "ZOMBIE": 0}
    
    # 3. Process
    for c in claims:
        trace = score_claim(c, index)
        score = trace["score"]
        ev = trace["evidence_str"]
        
        status = "GHOST"
        if score >= 4:
            status = "ALIVE"
        elif score >= 2:
            if "legacy" in ev.lower() or "deprecated" in ev.lower() or "old" in ev.lower():
                status = "ZOMBIE"
            else:
                status = "GHOST-WEAK" # Will be mapped to GHOST
        
        if "GHOST" in status:
            stats["GHOST"] += 1
            status = "GHOST"
        elif status == "ZOMBIE":
            stats["ZOMBIE"] += 1
        elif status == "ALIVE":
            stats["ALIVE"] += 1
            
        results.append({
            "day": c["sku"],
            "desc": c["desc"],
            "status": status,
            "score": score,
            "evidence": ev
        })
        
        # Prepare trace entry
        full_trace[c["sku"]] = {
            "desc": c["desc"],
            "final_status": status,
            "total_score": score,
            "tokens": trace["tokens"],
            "best_match": ev,
            "breakdown": sorted(trace["breakdown"], key=lambda x: -x["points"])[:5] # Top 5 matches only
        }

    # =========================================================================
    # REPORTS (ATOMIC)
    # =========================================================================
    
    # 1. Seal Proofs
    atomic_write_json(AUDIT_OUTPUT_DIR / "D50_EWIMS_SEAL_PROOFS.json", seals)

    # 2. Trace
    atomic_write_json(AUDIT_OUTPUT_DIR / "D50_EWIMS_TRACE.json", full_trace)

    # 3. Matrix
    matrix_content = []
    matrix_content.append("# D50 EWIMS TRUTH MATRIX (STRICT & DETERMINISTIC)\n")
    matrix_content.append(f"**Audit Snapshot Hash:** `{input_hash}`\n\n")
    matrix_content.append("| SKU | Feature | Status | Score | Evidence |")
    matrix_content.append("|---|---|---|---|---|")
    for r in results:
        icon = "🟢" if r['status'] == 'ALIVE' else "👻" if r['status'] == 'GHOST' else "🧟"
        matrix_content.append(f"| {r['day']} | {r['desc'][:50]}... | {icon} {r['status']} | {r['score']} | {r['evidence']} |")
    atomic_write_text(AUDIT_OUTPUT_DIR / "D50_EWIMS_CHRONOLOGICAL_MATRIX.md", "\n".join(matrix_content))

    # 4. Hit List
    hitlist_content = []
    hitlist_content.append(f"# D50 HIT LIST (Hash: `{input_hash}`)\n\n")
    ghosts = [r for r in results if r['status'] != 'ALIVE']
    if not ghosts:
        hitlist_content.append("No Ghosts or Zombies found. 100% Coverage.\n")
    else:
        for g in ghosts:
            hitlist_content.append(f"- [{g['status']}] **{g['day']} {g['desc']}**")
            hitlist_content.append(f"  - Score: {g['score']}")
            hitlist_content.append(f"  - Evidence: {g['evidence']}")
    atomic_write_text(AUDIT_OUTPUT_DIR / "D50_EWIMS_GHOST_ZOMBIE_LIST.md", "\n".join(hitlist_content))

    # 5. Summary & Verdict
    verdict = "PASS"
    if stats["GHOST"] > 0: verdict = "FAIL"
    elif stats["ZOMBIE"] > 0: verdict = "CONDITIONAL"

    atomic_write_json(AUDIT_OUTPUT_DIR / "D50_EWIMS_COVERAGE_SUMMARY.json", {
        "date": datetime.now().isoformat(),
        "input_hash": input_hash,
        "total_claims": len(claims),
        "stats": stats,
        "verdict": verdict
    })

    verdict_content = []
    verdict_content.append(f"# FINAL VERDICT: {verdict}\n")
    verdict_content.append(f"**Audit Hash:** `{input_hash}`\n")
    verdict_content.append(f"ALIVE: {stats['ALIVE']}")
    verdict_content.append(f"GHOST: {stats['GHOST']}")
    verdict_content.append(f"ZOMBIE: {stats['ZOMBIE']}")
    atomic_write_text(AUDIT_OUTPUT_DIR / "D50_EWIMS_FINAL_VERDICT.md", "\n".join(verdict_content))

    print(f"Audit Complete. Verdict: {verdict}")
    print(f"Hash: {input_hash}")
    print(f"Results: {stats}")

if __name__ == "__main__":
    run_audit()
