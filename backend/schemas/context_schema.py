from pydantic import BaseModel, Field
from typing import Dict, Any, Optional

class ContextPayload(BaseModel):
    """
    Represents the 'Brain' output: predictions, normalization maps, stat packs.
    For Day 02, we keep it minimal validation.
    """
    summary: str
    global_risk_score: float = 0.0
    generated_at: Optional[str] = None
    
    # Loose mapping for complex nested objects to avoid strict breakage early on
    daily_stat_pack: Dict[str, Any] = Field(default_factory=dict)
    normalization_map: Dict[str, Any] = Field(default_factory=dict)
