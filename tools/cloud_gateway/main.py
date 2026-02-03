import os
import logging
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
import httpx
import google.auth
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("gateway")

app = FastAPI()

TARGET_URL = os.environ.get("TARGET_URL", "https://marketsniper-api-3ygzdvszba-uc.a.run.app")

# Global HTTP Client
client = httpx.AsyncClient(timeout=60.0)

def get_id_token(target_audience: str) -> str:
    """
    Obtain ID Token for the Target Service using the underlying Service Account.
    """
    try:
        # Use default credential (Cloud Run Service Account)
        auth_req = GoogleRequest()
        token = id_token.fetch_id_token(auth_req, target_audience)
        return token
    except Exception as e:
        logger.error(f"Failed to get ID token: {e}")
        return None

@app.api_route("/{path:path}", methods=["OPTIONS"])
async def handle_options(path: str):
    """
    Handle CORS Preflight (OPTIONS) without Authentication.
    """
    # Simply return 204 with headers.
    response = Response(status_code=204)
    # Headers will be added by explicit middleware logic below or simple manual addition
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, X-Founder-Key, X-Requested-With"
    response.headers["Access-Control-Max-Age"] = "86400"
    return response

@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"])
async def proxy_request(request: Request, path: str):
    """
    Proxy request to TARGET_URL with ID Token.
    """
    # 1. Get ID Token
    token = get_id_token(TARGET_URL)
    if not token:
        return JSONResponse(status_code=500, content={"error": "Failed to obtain Gateway Authentication Token"})

    # 2. Construct Upstream URL
    url = f"{TARGET_URL}/{path}"
    if request.query_params:
        url += f"?{request.query_params}"

    # 3. Headers
    headers = dict(request.headers)
    headers["Authorization"] = f"Bearer {token}"
    headers["Host"] = TARGET_URL.replace("https://", "").replace("http://", "").split("/")[0]
    
    # Remove hop-by-hop headers
    headers.pop("content-length", None) # Let httpx handle recalculation
    headers.pop("host", None) # Set strictly above

    # 4. Body
    body = await request.body()

    try:
        upstream_resp = await client.request(
            method=request.method,
            url=url,
            headers=headers,
            content=body
        )
        
        # 5. Return Response
        # Copy headers from upstream
        excluded_headers = {"content-encoding", "content-length", "transfer-encoding", "connection"}
        resp_headers = {
            k: v for k, v in upstream_resp.headers.items() 
            if k.lower() not in excluded_headers
        }
        
        # Ensure CORS on response too
        resp_headers["Access-Control-Allow-Origin"] = "*"
        
        return Response(
            content=upstream_resp.content,
            status_code=upstream_resp.status_code,
            headers=resp_headers
        )

    except Exception as e:
        logger.error(f"Proxy error: {e}")
        return JSONResponse(status_code=502, content={"error": f"Gateway Proxy Error: {str(e)}"})
