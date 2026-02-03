
import subprocess
import httpx
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# CONFIG
TARGET_URL = "https://marketsniper-api-3ygzdvszba-uc.a.run.app"
PORT = 8787

app = FastAPI(title="MSR Local Proxy")

# 1. CORS (Permissive for Dev)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_identity_token():
    """Fetches Google Identity Token via gcloud CLI."""
    try:
        result = subprocess.run(
            ["gcloud", "auth", "print-identity-token"],
            capture_output=True,
            text=True,
            shell=True # Required on Windows for some envs
        )
        if result.returncode != 0:
            print(f"[PROXY] gcloud error: {result.stderr}")
            return None
        return result.stdout.strip()
    except Exception as e:
        print(f"[PROXY] gcloud exception: {e}")
        return None

@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"])
async def proxy_all(request: Request, path: str):
    """Forwards all requests to Cloud Run with injected Auth Token."""
    
    # 0. Handle OPTIONS locally (CORS preflight) handled by middleware automatically, 
    # but explicit return helps some browsers.
    if request.method == "OPTIONS":
        return Response(status_code=204)

    # 1. Get Token
    token = get_identity_token()
    if not token:
        return JSONResponse(
            status_code=500, 
            content={"error": "Failed to get gcloud identity token. Run 'gcloud auth login'."}
        )

    # 2. Prepare Target URL
    target = f"{TARGET_URL}/{path}"
    if request.url.query:
        target += f"?{request.url.query}"

    print(f"[PROXY] {request.method} {path} -> {target}")

    # 3. Prepare Headers
    headers = dict(request.headers)
    headers["Authorization"] = f"Bearer {token}"
    headers["Host"] = TARGET_URL.replace("https://", "").replace("http://", "")
    
    # Remove hop-by-hop headers that confuse Cloud Run
    for key in ["host", "connection", "content-length", "accept-encoding"]:
        if key in headers:
            del headers[key]

    # 4. Forward Request
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            # Body
            body = await request.body()
            
            resp = await client.request(
                method=request.method,
                url=target,
                headers=headers,
                content=body
            )
            
            # 5. Return Response
            # Filter response headers
            excluded_headers = {"content-encoding", "content-length", "transfer-encoding", "connection"}
            response_headers = {
                k: v for k, v in resp.headers.items() 
                if k.lower() not in excluded_headers
            }
            
            print(f"[PROXY] <- {resp.status_code}")
            
            return Response(
                content=resp.content,
                status_code=resp.status_code,
                headers=response_headers,
                media_type=resp.headers.get("content-type")
            )

        except Exception as e:
            print(f"[PROXY] Upstream Error: {e}")
            return JSONResponse(status_code=502, content={"error": str(e)})

if __name__ == "__main__":
    import uvicorn
    print(f"\n[PROXY] Listening on http://localhost:{PORT}")
    print(f"[PROXY] Target: {TARGET_URL}")
    print(f"[PROXY] Auth: Auto-injecting gcloud identity token\n")
    uvicorn.run(app, host="127.0.0.1", port=PORT)
