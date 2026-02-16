#!/usr/bin/env python3
import os
import json
import hashlib
from pathlib import Path
from datetime import datetime

# Configuration
OUTPUTS_ROOT = Path("outputs")
SEALS_DIR = OUTPUTS_ROOT / "seals"
PROOFS_DIR = OUTPUTS_ROOT / "proofs"
CANON_DIR = Path("docs/canon")
AUDIT_DIR = OUTPUTS_ROOT / "audit"

AUDIT_DIR.mkdir(parents=True, exist_ok=True)

def calculate_hash(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def scan_directory(directory, allowed_extensions=[".md", ".json", ".txt"]):
    inventory = {}
    if not directory.exists():
        return inventory
    
    for root, _, files in os.walk(directory):
        for file in files:
            if any(file.endswith(ext) for ext in allowed_extensions):
                file_path = Path(root) / file
                try:
                    # Handle symlinks/mounts by force-resolving relative path from CWD
                    # If realpath is outside, we just use the logical path components
                    rel_path = Path(os.path.relpath(file_path, Path.cwd())).as_posix()
                    meta = {
                        "path": rel_path,
                        "size": file_path.stat().st_size,
                        "hash": calculate_hash(file_path),
                        "modified": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat()
                    }
                    inventory[rel_path] = meta
                except Exception as e:
                    print(f"[ERROR] processing {file}: {e}")
    return inventory

def main():
    print("Starting Artifact Integrity Audit...")
    
    seals = scan_directory(SEALS_DIR)
    proofs = scan_directory(PROOFS_DIR)
    canon = scan_directory(CANON_DIR)
    
    total_inventory = {
        "timestamp": datetime.now().isoformat(),
        "stats": {
            "seals_count": len(seals),
            "proofs_count": len(proofs),
            "canon_count": len(canon)
        },
        "seals": seals,
        "proofs": proofs,
        "canon": canon
    }
    
    # Save Inventory
    inventory_path = AUDIT_DIR / "ARTIFACT_INVENTORY.json"
    with open(inventory_path, "w") as f:
        json.dump(total_inventory, f, indent=2)
    
    print(f"[PASS] Inventory generated: {inventory_path}")
    print(f"Stats: Seals={len(seals)}, Proofs={len(proofs)}, Canon={len(canon)}")
    
    # Loss Ledger (Placeholder for detailed drift logic in v2)
    # For now, we just document what we found. 
    # Logic to compare against a "PREVIOUS_INVENTORY.json" would go here.
    
    loss_ledger = {
        "timestamp": datetime.now().isoformat(),
        "missing_seals": [], # To be populated if we add diff logic against known good state
        "drift_warnings": []
    }
    
    loss_path = AUDIT_DIR / "LOSS_LEDGER.json"
    with open(loss_path, "w") as f:
        json.dump(loss_ledger, f, indent=2)
        
    print(f"[PASS] Loss/Drift Ledger initialized: {loss_path}")

if __name__ == "__main__":
    main()
