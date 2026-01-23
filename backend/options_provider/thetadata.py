from .base import OptionsProvider

class ThetaDataProvider(OptionsProvider):
    def get_name(self) -> str:
        return "THETADATA"

    def is_configured(self) -> bool:
        # Check for local terminal port or key
        return False 

    def fetch_snapshot(self, symbol: str) -> dict:
        raise PermissionError("THETADATA_NOT_CONFIGURED")
