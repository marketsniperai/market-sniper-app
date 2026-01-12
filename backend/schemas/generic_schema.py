from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List

class GenericReport(BaseModel):
    """
    Fallback schema for new artifacts until explicit schemas are defined.
    Pragmatic validation.
    """
    timestamp: Optional[str] = None
    generated_at: Optional[str] = None
    run_id: Optional[str] = None
    
    # Allow extra fields
    class Config:
        extra = "allow"
