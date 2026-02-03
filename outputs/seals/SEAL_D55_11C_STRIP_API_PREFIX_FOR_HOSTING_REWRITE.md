# SEAL_D55_11C_STRIP_API_PREFIX_FOR_HOSTING_REWRITE

## Status
**STATUS:** GREEN (VERIFIED)

## Summary
Cloud Run backend now strips the `/api` prefix for incoming requests using `StripApiPrefixMiddleware`.
This enables Firebase Hosting `run.serviceId` rewrites (which do not strip prefixes) to successfully hit the existing root routes without duplication.

## Verification
- **Direct API:** `https://api.marketsniperai.com/health_ext` -> **200 OK**
- **Web Rewrite:** `https://marketsniper-intel-osr-9953.web.app/api/health_ext` -> **200 OK**
- **Middleware:** confirmed active via `X-Founder-Trace` and correct routing.

## Evidence
- `outputs/proofs/d55_11c_strip_api_prefix/1_api_health.txt` (Direct 200)
- `outputs/proofs/d55_11c_strip_api_prefix/2_web_api_health.txt` (Rewrite 200)
- `outputs/proofs/d55_11c_strip_api_prefix/_summary.txt`

## Technical Note
The middleware was implemented without `starlette` type hints to avoid build-time dependency issues in the Cloud Run container.
