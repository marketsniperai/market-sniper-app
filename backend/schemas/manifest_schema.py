from pydantic import BaseModel, Field
from typing import Optional, Dict

class RunManifest(BaseModel):
    run_id: str
    build_id: str
    timestamp: str
    status: str
    mode: str = "FULL"
    window: str = "UNKNOWN"
    schema_version: Optional[str] = "1.0"
    
    # Detailed Status
    capabilities: Dict[str, str] = Field(default_factory=dict) # e.g. {"prices": "STUB"}
    data_status: Dict[str, str] = Field(default_factory=dict) # e.g. {"prices": "OK"}
    freshness: Dict[str, float] = Field(default_factory=dict) # age in seconds
    
    # Optional extended properties
    pipeline_type: Optional[str] = None
    runner_host: Optional[str] = None
