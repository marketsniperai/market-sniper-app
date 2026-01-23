
def compute_options_context(snapshot: dict) -> dict:
    """
    Deterministically transforms raw provider data into descriptive context.
    
    Inputs:
    - snapshot: dict containing 'raw_iv', 'raw_skew', 'underlying_price'
    
    Outputs:
    - dict with 'iv_regime', 'skew', 'expected_move', 'notes'
    """
    raw_iv = snapshot.get('raw_iv')
    raw_skew = snapshot.get('raw_skew')
    price = snapshot.get('underlying_price', 0)
    
    # 1. IV Regime (Simplistic Thresholds for v1.1)
    # Mapping: <10% Low, 10-20% Normal, >20% Elevated (for SPY/Major Indices)
    iv_regime = "N/A"
    if raw_iv is not None:
        if raw_iv < 0.10: iv_regime = "Low"
        elif raw_iv < 0.20: iv_regime = "Normal"
        else: iv_regime = "Elevated"
        
    # 2. Skew
    skew_val = "N/A"
    if raw_skew is not None:
        if raw_skew < -0.05: skew_val = "Put Skew"
        elif raw_skew > 0.05: skew_val = "Call Skew"
        else: skew_val = "Balanced"
        
    # 3. Expected Move (1D)
    # Formula: Price * IV * sqrt(1/252)
    expected_move = "N/A"
    if raw_iv is not None and price > 0:
        move_val = price * raw_iv * 0.063 # 0.063 ~= sqrt(1/252)
        expected_move = f"+/- ${move_val:.2f}"
        
    return {
        "iv_regime": iv_regime,
        "skew": skew_val,
        "expected_move": expected_move,
        "expected_move_horizon": "1D"
    }
