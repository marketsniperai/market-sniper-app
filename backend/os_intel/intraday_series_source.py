import hashlib
import datetime
from typing import List, Dict, Any, Optional

class IntradayCandle:
    def __init__(self, t_utc: str, o: float, h: float, l: float, c: float, v: Optional[float] = None, is_ghost: bool = False):
        self.t_utc = t_utc
        self.o = o
        self.h = h
        self.l = l
        self.c = c
        self.v = v
        self.is_ghost = is_ghost
    
    def to_dict(self):
        return {
            "tUtc": self.t_utc,
            "o": round(self.o, 2),
            "h": round(self.h, 2),
            "l": round(self.l, 2),
            "c": round(self.c, 2),
            "v": self.v,
            "isGhost": self.is_ghost
        }

class DemoIntradaySeriesSource:
    """
    D47.HF18: Deterministic Demo Intraday Series using seeded randomness.
    Strictly no external data.
    """
    
    @staticmethod
    def _seeded_random(seed_str: str) -> float:
        """Returns 0.0 to 1.0 deterministic float from seed."""
        hash_val = hashlib.sha256(seed_str.encode()).hexdigest()
        # Convert first 8 chars of hex to int, then normalize
        int_val = int(hash_val[:8], 16)
        return int_val / 0xFFFFFFFF

    @staticmethod
    def generate_series(symbol: str, as_of_utc: datetime.datetime, horizon_min: int = 60, is_stress: bool = False) -> List[Dict[str, Any]]:
        
        # 1. Base Seed
        date_str = as_of_utc.strftime("%Y-%m-%d")
        base_seed = f"{symbol}-{date_str}-DEMO"
        
        # 2. Base Price (Mock Anchor)
        # We start at arbitrary price based on symbol hash to keep it stable per day
        start_price = 100.0 + (DemoIntradaySeriesSource._seeded_random(base_seed) * 400.0) # 100-500
        
        # 3. Volatility
        vol_seed = f"{base_seed}-VOL"
        vol_base = 0.002 # 0.2% per 5m candle (~2% daily range roughly)
        if is_stress:
            vol_base *= 2.5 
            
        points = []
        current_price = start_price
        
        # Generate Past 60m (12 candles of 5m) + Future (Ghost) 60m (12 candles)
        # Total 24 candles centred on 'now'
        
        # We want t=0 to be 'now'.
        # Let's align to nearest 5m for cleanliness
        minute_base = as_of_utc.minute - (as_of_utc.minute % 5)
        anchor_time = as_of_utc.replace(minute=minute_base, second=0, microsecond=0)
        
        # Past: t - 60m to t
        start_time = anchor_time - datetime.timedelta(minutes=60)
        
        for i in range(25): # 0 to 24 (12 past, 1 now, 12 future)
            # Time
            candle_time = start_time + datetime.timedelta(minutes=i * 5)
            is_ghost = candle_time > anchor_time
            
            # Deterministic Step
            step_seed = f"{base_seed}-{i}"
            rnd = DemoIntradaySeriesSource._seeded_random(step_seed) # 0..1
            
            # Random Walk (-1 to 1) * Vol
            move_pct = (rnd - 0.5) * 2 * vol_base
            
            # Update Price
            open_p = current_price
            close_p = open_p * (1 + move_pct)
            
            # High/Low wicks
            high_p = max(open_p, close_p) * (1 + (DemoIntradaySeriesSource._seeded_random(step_seed+"H") * 0.001))
            low_p = min(open_p, close_p) * (1 - (DemoIntradaySeriesSource._seeded_random(step_seed+"L") * 0.001))
            
            # Stress Drift (downward bias usually for stress, or higher vol)
            if is_stress and is_ghost:
                 close_p *= 0.999 # Slight drag
            
            candle = IntradayCandle(
                t_utc=candle_time.isoformat() + "Z",
                o=open_p, h=high_p, l=low_p, c=close_p,
                v=1000, # Stub volume
                is_ghost=is_ghost
            )
            points.append(candle.to_dict())
            
            current_price = close_p
            
        return points

class IntradaySeriesSource:
    """Public Facade"""
    @staticmethod
    def load(symbol: str, as_of_utc: datetime.datetime = None) -> Dict[str, Any]:
        if not as_of_utc:
            as_of_utc = datetime.datetime.utcnow()
            
        # V0: Always Demo
        base_series = DemoIntradaySeriesSource.generate_series(symbol, as_of_utc, is_stress=False)
        stress_series = DemoIntradaySeriesSource.generate_series(symbol, as_of_utc, is_stress=True)
        
        # Split logic could be here, but orchestrator might want raw full arrays
        # Contract says:
        # intraday: { intervalMin:5, pastCandles:[...], nowCandle:{...} }
        # projection: { baseCandles:[...], stressCandles:[...], ... }
        
        # Filter Past/Now vs Future
        # 'now' is the anchor candle (last non-ghost or first ghost? usually last closed)
        # Our demo logic marks ghost based on anchor_time
        
        past_candles = [c for c in base_series if not c['isGhost']]
        future_base = [c for c in base_series if c['isGhost']]
        future_stress = [c for c in stress_series if c['isGhost']]
        
        # Now candle is last of past, strictly speaking? Or current forming?
        # Logic: Let's say past_candles includes the "current forming" one as the anchor for chart continuity.
        # But wait, isGhost was > anchor_time. So anchor_time candle is NOT ghost.
        now_candle = past_candles[-1] if past_candles else None
        
        return {
            "source": "DEMO_DETERMINISTIC",
            "intervalMin": 5,
            "pastCandles": past_candles,
            "nowCandle": now_candle,
            "futureBase": future_base,
            "futureStress": future_stress
        }
