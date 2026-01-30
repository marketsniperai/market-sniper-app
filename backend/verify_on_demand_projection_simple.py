import asyncio
from backend.api_server import get_on_demand_context
import json

async def check():
    print("RUNNING PROOF...")
    res = await get_on_demand_context(ticker="SPY", x_founder_key=None)
    
    # Dump just the projection key if it exists
    if hasattr(res, "body"):
        print("Got JSONResponse, body len:", len(res.body))
    else:
        # Assume dict envelope
        print("Got Envelope. Keys:", list(res.keys()))
        if "projection" in res:
             print("PROJECTION found:")
             print(json.dumps(res["projection"], indent=2, default=str))
        else:
             print("PROJECTION MISSING")

if __name__ == "__main__":
    loop = asyncio.new_event_loop()
    loop.run_until_complete(check())
