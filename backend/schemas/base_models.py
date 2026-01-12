from pydantic import BaseModel, Field
from typing import List, Optional, Any, Generic, TypeVar
from datetime import datetime
import uuid

T = TypeVar("T")

class FallbackEnvelope(BaseModel, Generic[T]):
    """
    Standard envelope for all "Lens" reads.
    Wraps the actual schema (T) or provides reasons for failure.
    """
    status: str = Field(..., description="LIVE, CALIBRATING, or MISSING_ARTIFACT")
    as_of_utc: str = Field(..., description="Timestamp of the read or fallback generation")
    schema_version: str = "1.0"
    partial: bool = Field(False, description="True if this is a safe fallback/partial read")
    reason_codes: List[str] = Field(default_factory=list, description="Why valid data is missing")
    payload: Optional[T] = None

    @classmethod
    def create_fallback(cls, status: str, reasons: List[str]):
        return cls(
            status=status,
            as_of_utc=datetime.utcnow().isoformat(),
            partial=True,
            reason_codes=reasons,
            payload=None
        )

    @classmethod
    def create_valid(cls, payload: T, status: str = "LIVE"):
        return cls(
            status=status,
            as_of_utc=datetime.utcnow().isoformat(),
            partial=False,
            payload=payload
        )
