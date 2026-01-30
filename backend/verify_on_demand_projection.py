
import asyncio
from backend.api_server import get_on_demand_context
import json

async def run_test():
    print("Testing get_on_demand_context for SPY...")
    # Mock request headers not needed for default run, but let's emulate what we can or just call function.
    # The function is async and takes params.
    
    # We need to mock headers? No, it uses FastAPI Header dependency which is resolved at runtime.
    # Calling python function directly: default args apply. x_founder_key=None.
    
    try:
        # Note: calling fastapi path operation function directly requires passing arguments manually 
        # and doesn't inject dependencies automatically. 
        # x_founder_key defaults to Header(None), but in direct call it's just the default value of the arg if not passed? 
        # Wait, Header(None) is a Pydantic/FastAPI thing. The default value is that object.
        # We should pass None explicitly if we want to simulate missing header.
        response = await get_on_demand_context(ticker="SPY", tier="FREE", allow_stale=False, x_founder_key=None)
        
        # Responses might be JSONResponse or dict. 
        # Standard returns dict via with_meta usually, unless error (JSONResponse).
        if hasattr(response, "body"):
            print("Response is JSONResponse:")
            print(response.body.decode())
        else:
            print("Response is Dict:")
            # masking bulky data
            if "payload" in response: response["payload"] = "..." 
            print(json.dumps(response, indent=2, default=str))

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
