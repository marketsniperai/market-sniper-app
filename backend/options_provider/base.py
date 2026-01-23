# Abstract Base for Options Providers
import abc
from datetime import datetime

class OptionsProvider(abc.ABC):
    @abc.abstractmethod
    def get_name(self) -> str:
        """Return provider name (e.g. 'POLYGON', 'THETADATA')"""
        pass

    @abc.abstractmethod
    def is_configured(self) -> bool:
        """Return True if API keys/env vars are present"""
        pass

    @abc.abstractmethod
    def fetch_snapshot(self, symbol: str) -> dict:
        """
        Fetch raw options snapshot.
        Returns dict or raises exception.
        Should include:
        - raw_iv
        - raw_skew (if available)
        - underlying_price
        - timestamp_utc
        """
        pass
