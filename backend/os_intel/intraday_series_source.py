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

class DemoSeriesGenerator:
    """
    D47.HF18/HF-B: Deterministic Demo Series Generator.
    Supports Intraday (5m) and Weekly (Daily Candles) modes.
    Strictly no external data.
    """
    
    @staticmethod
    def _seeded_random(seed_str: str) -> float:
        """Returns 0.0 to 1.0 deterministic float from seed."""
        hash_val = hashlib.sha256(seed_str.encode()).hexdigest()
        int_val = int(hash_val[:8], 16)
        return int_val / 0xFFFFFFFF

    @staticmethod
    def generate_intraday(symbol: str, as_of_utc: datetime.datetime, is_stress: bool = False, volatility_scale: float = 1.0) -> List[Dict[str, Any]]:
        # 1. Base Seed
        date_str = as_of_utc.strftime("%Y-%m-%d")
        base_seed = f"{symbol}-{date_str}-DEMO-INTRA"
        
        start_price = 100.0 + (DemoSeriesGenerator._seeded_random(base_seed) * 400.0) 
        
        vol_seed = f"{base_seed}-VOL"
        vol_base = 0.002 * volatility_scale 
        if is_stress: vol_base *= 2.5 
            
        points = []
        current_price = start_price
        
        minute_base = as_of_utc.minute - (as_of_utc.minute % 5)
        anchor_time = as_of_utc.replace(minute=minute_base, second=0, microsecond=0)
        start_time = anchor_time - datetime.timedelta(minutes=60)
        
        for i in range(25): 
            candle_time = start_time + datetime.timedelta(minutes=i * 5)
            is_ghost = candle_time > anchor_time
            
            step_seed = f"{base_seed}-{i}"
            rnd = DemoSeriesGenerator._seeded_random(step_seed) 
            move_pct = (rnd - 0.5) * 2 * vol_base
            
            open_p = current_price
            close_p = open_p * (1 + move_pct)
            high_p = max(open_p, close_p) * (1 + (DemoSeriesGenerator._seeded_random(step_seed+"H") * 0.001))
            low_p = min(open_p, close_p) * (1 - (DemoSeriesGenerator._seeded_random(step_seed+"L") * 0.001))
            
            if is_stress and is_ghost: close_p *= 0.999 
            
            candle = IntradayCandle(
                t_utc=candle_time.isoformat() + "Z",
                o=open_p, h=high_p, l=low_p, c=close_p, v=1000, is_ghost=is_ghost
            )
            points.append(candle.to_dict())
            current_price = close_p
            
        return points

    @staticmethod
    def generate_weekly(symbol: str, as_of_utc: datetime.datetime, is_stress: bool = False, volatility_scale: float = 1.0) -> List[Dict[str, Any]]:
        """
        Generates 5 Daily Candles for the current week (Mon-Fri).
        Marks future days as ghost based on as_of_utc weekday.
        """
        # 1. Determine Monday of current week
        # weekday(): Mon=0, Sun=6
        weekday = as_of_utc.weekday()
        monday = as_of_utc - datetime.timedelta(days=weekday)
        monday = monday.replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Base Seed (Week specific)
        week_str = monday.strftime("%Y-W%U")
        base_seed = f"{symbol}-{week_str}-DEMO-WEEKLY"
        
        start_price = 100.0 + (DemoSeriesGenerator._seeded_random(base_seed) * 400.0) 
        
        vol_base = 0.01 * volatility_scale # Higher vol for daily candles (1%)
        if is_stress: vol_base *= 2.0
        
        points = []
        current_price = start_price
        
        for i in range(5): # Mon(0) to Fri(4)
            day_time = monday + datetime.timedelta(days=i)
            # Ghost logic: If day_time > today (date comparison), it's ghost.
            # If day_time == today, it's NOT ghost (it's 'now' or developing).
            # Actually, let's keep it simple: 
            # If i > weekday, it's ghost. 
            # If i == weekday, it's the "Now" candle (solid/forming).
            # If i < weekday, it's Past candle (solid).
            
            is_ghost = i > weekday
            
            # Deterministic Step
            step_seed = f"{base_seed}-{i}"
            rnd = DemoSeriesGenerator._seeded_random(step_seed)
            move_pct = (rnd - 0.5) * 2 * vol_base
            
            open_p = current_price
            close_p = open_p * (1 + move_pct)
            high_p = max(open_p, close_p) * (1 + (DemoSeriesGenerator._seeded_random(step_seed+"H") * 0.005))
            low_p = min(open_p, close_p) * (1 - (DemoSeriesGenerator._seeded_random(step_seed+"L") * 0.005))

            if is_stress and is_ghost: close_p *= 0.98 # Drag down context for stress
            
            # Use noon for candle time
            candle_time = day_time.replace(hour=12)
            
            candle = IntradayCandle(
                t_utc=candle_time.isoformat() + "Z",
                o=open_p, h=high_p, l=low_p, c=close_p, v=50000, is_ghost=is_ghost
            )
            points.append(candle.to_dict())
            current_price = close_p
            
        return points

class SeriesSource:
    """Public Facade (was IntradaySeriesSource)"""
    
    @staticmethod
    def load(symbol: str, as_of_utc: datetime.datetime = None, volatility_scale: float = 1.0, timeframe: str = "DAILY") -> Dict[str, Any]:
        if not as_of_utc:
            as_of_utc = datetime.datetime.utcnow()
            
        # Select Generator
        if timeframe == "WEEKLY":
             base_series = DemoSeriesGenerator.generate_weekly(symbol, as_of_utc, is_stress=False, volatility_scale=volatility_scale)
             stress_series = DemoSeriesGenerator.generate_weekly(symbol, as_of_utc, is_stress=True, volatility_scale=volatility_scale)
             interval = 1440 # 24h
        else: # DAILY / INTRADAY default
             base_series = DemoSeriesGenerator.generate_intraday(symbol, as_of_utc, is_stress=False, volatility_scale=volatility_scale)
             stress_series = DemoSeriesGenerator.generate_intraday(symbol, as_of_utc, is_stress=True, volatility_scale=volatility_scale)
             interval = 5 # 5m

        # Partition
        past_candles = [c for c in base_series if not c['isGhost']]
        future_base = [c for c in base_series if c['isGhost']]
        future_stress = [c for c in stress_series if c['isGhost']]
        
        now_candle = past_candles[-1] if past_candles else None
        
        return {
            "source": "DEMO_DETERMINISTIC",
            "timeframe": timeframe,
            "intervalMin": interval,
            "pastCandles": past_candles,
            "nowCandle": now_candle,
            "futureBase": future_base,
            "futureStress": future_stress
        }

# Compat Alias
IntradaySeriesSource = SeriesSource
