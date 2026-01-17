import os
import shutil
import hashlib
import json
from datetime import datetime
from pathlib import Path

def calculate_sha256(filepath):
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def main():
    repo_root = Path(os.getcwd())
    app_build_dir = repo_root / "market_sniper_app" / "build" / "app" / "outputs" / "flutter-apk"
    
    debug_apk = app_build_dir / "app-debug.apk"
    release_apk = app_build_dir / "app-release.apk"
    
    target_dir = Path("C:/Users/Sergio B/OneDrive/Desktop/Apk Release")
    target_dir.mkdir(parents=True, exist_ok=True)
    
    now = datetime.now()
    timestamp_str = now.strftime("%Y%m%d_%H%M")
    
    debug_target_name = f"MarketSniper_debug_{timestamp_str}.apk"
    release_target_name = f"MarketSniper_release_{timestamp_str}.apk"
    
    debug_target = target_dir / debug_target_name
    release_target = target_dir / release_target_name
    
    proof = {
        "timestamp_utc": datetime.utcnow().isoformat(),
        "git_branch": "master", # fallback assumption
        "copy_operations": [],
        "apks": {}
    }
    
    # Process Debug
    if debug_apk.exists():
        shutil.copy2(debug_apk, debug_target)
        sha = calculate_sha256(debug_target)
        size = debug_target.stat().st_size
        print(f"Copied Debug APK to: {debug_target}")
        proof["copy_operations"].append(f"Copied {debug_apk} to {debug_target}")
        proof["apks"]["debug"] = {
            "path": str(debug_target),
            "sha256": sha,
            "size_bytes": size
        }
    else:
        print(f"ERROR: Debug APK not found at {debug_apk}")
        
    # Process Release
    if release_apk.exists():
        shutil.copy2(release_apk, release_target)
        sha = calculate_sha256(release_target)
        size = release_target.stat().st_size
        print(f"Copied Release APK to: {release_target}")
        proof["copy_operations"].append(f"Copied {release_apk} to {release_target}")
        proof["apks"]["release"] = {
            "path": str(release_target),
            "sha256": sha,
            "size_bytes": size
        }
    else:
         print(f"ERROR: Release APK not found at {release_apk}")

    # Save proof
    proof_dir = repo_root / "outputs" / "runtime" / "day_42"
    proof_dir.mkdir(parents=True, exist_ok=True)
    proof_path = proof_dir / "day_42_build_apk_proof.json"
    
    with open(proof_path, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof generated at: {proof_path}")

if __name__ == "__main__":
    main()
