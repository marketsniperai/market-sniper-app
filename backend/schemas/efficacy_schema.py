from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional

class LedgerEntry(BaseModel):
    symbol: str
    action: str
    timestamp: str

class EfficacyReport(BaseModel):
    report_id: str
    generated_at: str
    
    overall_win_rate: float
    total_trades: int
    
    ledger: List[LedgerEntry] = Field(default_factory=list)
