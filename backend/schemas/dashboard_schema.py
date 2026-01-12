from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional

class DashboardWidget(BaseModel):
    id: str
    type: str # e.g. "CARD_DELTA", "CARD_WATCHLIST"
    title: str
    data: Dict[str, Any] = Field(default_factory=dict)

class DashboardPayload(BaseModel):
    system_status: str
    message: str
    widgets: List[DashboardWidget]
    generated_at: Optional[str] = None
    
    # Forensic trace is often injected dynamically, but we can model it if present
    forensic_trace: Optional[Dict[str, Any]] = None
