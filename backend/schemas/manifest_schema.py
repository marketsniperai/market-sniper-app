from pydantic import BaseModel, Field
from typing import Optional

class RunManifest(BaseModel):
    run_id: str
    build_id: str
    timestamp: str
    status: str
    schema_version: Optional[str] = "1.0"

    # Optional extended properties
    pipeline_type: Optional[str] = None
    runner_host: Optional[str] = None
