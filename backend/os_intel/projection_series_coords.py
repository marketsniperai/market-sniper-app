from typing import List, Dict, Any

class ProjectionSeriesCoords:
    """
    D47.HF18: Series Coordinate Normalizer.
    Converts raw price candles into standard [0..1] chart usage coordinates.
    Simplifies Frontend logic (no min/max math needed in UI).
    """
    
    @staticmethod
    def compute_coords(past_candles: List[Dict], future_base: List[Dict], future_stress: List[Dict]) -> Dict[str, Any]:
        """
        Input: Raw Candle Arrays.
        Output: Normalized { upper: [...], lower: [...] } for cones (simplified for v0)
                And we could attach min/max for scaling.
        For V0: We define the "Cone" simply as the envelope arrays themselves.
        The UI (RegimeSentinel) will paint the candles directly if provided prices?
        Wait, UI scope said "Series Coords for charting: normalized [0..1]".
        
        So we must return the normalized Y values for the candles?
        Actually, standard practice: Provide Min/Max boundaries in the payload, 
        and let UI scale? Or normalize here?
        
        Scope says: "normalized [0..1] x positions, normalized [0..1] y positions"
        
        Okay, let's enable the UI to draw path.
        """
        
        all_candles = past_candles + future_base + future_stress
        if not all_candles:
            return {"yMin": 0, "yMax": 100, "xStep": 0}
            
        prices = [c['c'] for c in all_candles] + [c['h'] for c in all_candles] + [c['l'] for c in all_candles]
        min_p = min(prices)
        max_p = max(prices)
        range_p = max_p - min_p if max_p != min_p else 1.0
        
        # Buffer
        min_p -= range_p * 0.1
        max_p += range_p * 0.1
        final_range = max_p - min_p
        
        # We return the Bounds so UI can render tooltips if needed,
        # AND we could optionally return pre-calc points. 
        # For V0, let's return the BOUNDS (Cone) which allows 0..1 normalization.
        
        return {
            "yMin": min_p,
            "yMax": max_p, 
            "yRange": final_range,
            "count": len(past_candles) + len(future_base) # total horizon
        }
