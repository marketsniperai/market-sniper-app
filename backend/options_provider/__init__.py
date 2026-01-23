from .base import OptionsProvider
from .polygon import PolygonOptionsProvider
from .thetadata import ThetaDataProvider

def get_provider() -> OptionsProvider:
    """Factory to get the best available provider."""
    # Priority 1: Polygon
    poly = PolygonOptionsProvider()
    if poly.is_configured():
        return poly
    
    # Priority 2: ThetaData
    theta = ThetaDataProvider()
    if theta.is_configured():
        return theta
        
    # Return Polygon as default even if unconfigured (it will just report denied)
    return poly
