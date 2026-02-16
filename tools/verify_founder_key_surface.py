import os
import sys
import subprocess
import json

def run_command(command):
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {command}")
        print(f"Stderr: {e.stderr}")
        return None

def check_backend_config():
    print("--- CHECKING BACKEND CONFIG ---")
    config_path = "backend/config.py"
    if not os.path.exists(config_path):
        print("FAIL: backend/config.py not found.")
        return False
    
    with open(config_path, "r") as f:
        content = f.read()
        if 'FOUNDER_KEY = os.getenv("FOUNDER_KEY", "")' in content:
            print("PASS: FOUNDER_KEY defined correctly in config.py")
            return True
        else:
            print("FAIL: FOUNDER_KEY definition mismatch in config.py")
            return False

def check_cloud_run_service():
    print("\n--- CHECKING CLOUD RUN SERVICE (marketsniper-api) ---")
    cmd = 'gcloud run services describe marketsniper-api --region us-central1 --format="json"'
    output = run_command(cmd)
    if not output:
        print("FAIL: Could not fetch Cloud Run service config.")
        return False
    
    try:
        data = json.loads(output)
        containers = data['spec']['template']['spec']['containers']
        found_key = False
        for container in containers:
            env_vars = container.get('env', [])
            for env in env_vars:
                if env['name'] == 'FOUNDER_KEY':
                    print("PASS: FOUNDER_KEY found in Cloud Run env vars.")
                    # Masked value check if possible/needed, but presence is key here.
                    found_key = True
                    break
        
        if not found_key:
            print("FAIL: FOUNDER_KEY MISSING in Cloud Run env vars.")
            return False
            
        return True

    except json.JSONDecodeError:
        print("FAIL: Invalid JSON from gcloud.")
        return False
    except Exception as e:
        print(f"FAIL: Error parsing Cloud Run config: {e}")
        return False

def check_cloud_run_job():
    print("\n--- CHECKING CLOUD RUN JOB (market-sniper-pipeline) ---")
    cmd = 'gcloud run jobs describe market-sniper-pipeline --region us-central1 --format="json"'
    output = run_command(cmd)
    if not output:
        # If job doesn't exist, maybe warn but don't fail if not critical yet?
        # Prompt said "Drift Prevention... Validar FOUNDER_KEY existe en service y en job"
        print("FAIL: Could not fetch Cloud Run job config.")
        return False
    
    try:
        data = json.loads(output)
        # Job structure is spec -> template -> spec -> template -> spec -> containers
        # Based on actual output: spec.template.spec.template.spec.containers
        containers = data['spec']['template']['spec']['template']['spec']['containers']
        found_key = False
        for container in containers:
            env_vars = container.get('env', [])
            for env in env_vars:
                if env['name'] == 'FOUNDER_KEY':
                    print("PASS: FOUNDER_KEY found in Cloud Run Job env vars.")
                    found_key = True
                    break
        
        if not found_key:
            print("FAIL: FOUNDER_KEY MISSING in Cloud Run Job env vars.")
            return False
            
        return True

    except json.JSONDecodeError:
        print("FAIL: Invalid JSON from gcloud.")
        return False
    except KeyError as e:
        print(f"FAIL: Unexpected JSON structure (KeyError: {e})")
        return False
    except Exception as e:
        print(f"FAIL: Error parsing Cloud Run Job config: {e}")
        return False

def verify_audit():
    print("=== FOUNDER KEY SURFACE VERIFICATION ===\n")
    backend_ok = check_backend_config()
    service_ok = check_cloud_run_service()
    job_ok = check_cloud_run_job()
    
    if backend_ok and service_ok and job_ok:
        print("\n[VERDICT]: SYSTEM HEALTHY (PASS)")
        sys.exit(0)
    else:
        print("\n[VERDICT]: SYSTEM DRIFT DETECTED (FAIL)")
        sys.exit(1)

if __name__ == "__main__":
    verify_audit()
