
import asyncio
from backend.api_server import get_on_demand_context
import json

async def run_test():
    print("Testing get_on_demand_context for SPY...")
    try:
        response = await get_on_demand_context(ticker="SPY", tier="FREE", allow_stale=False, x_founder_key=None)
        
        # Responses might be JSONResponse or dict.
        is_response_obj = hasattr(response, "body")
        
        if is_response_obj:
            print("Response is JSONResponse:")
            print(response.body.decode())
        else:
            print("Response is Dict:")
            # masking bulky data
            data = response.copy()
            if "payload" in data: 
                data["payload"] = "..." 
            print(json.dumps(data, indent=2, default=str))

            if "projection" in response:
                print("\n[PASS] Projection field found!")
                print(json.dumps(response["projection"], indent=2))
            else:
                print("\n[FAIL] Projection field MISSING.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    loop = asyncio.new_event_loop()
    loop.run_until_complete(run_test())
