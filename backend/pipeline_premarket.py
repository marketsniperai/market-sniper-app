import uuid
import os
from backend.pipeline_full import run_full_pipeline

if __name__ == "__main__":
    # Ensure outputs directory exists
    os.makedirs("/app/backend/outputs", exist_ok=True)
    
    run_id = str(uuid.uuid4())
    print(f"Starting pipeline run: {run_id}")
    try:
        generated = run_full_pipeline(run_id)
        print(f"Generated artifacts: {generated}")
    except Exception as e:
        print(f"Pipeline failed: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
