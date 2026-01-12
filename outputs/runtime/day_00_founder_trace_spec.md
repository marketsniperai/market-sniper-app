# Founder Trace Spec (Day 00)

## Overview
Founder mode is currently "Always-On".

## Headers
- **Request**: `X-Founder-Key` (Optional stub)
- **Response**: `X-Founder-Trace`: `FOUNDER_BUILD=TRUE; KEY_SENT={true/false}`

## Payload
- `/health_ext`: Includes `"founder_mode": true`
- `/dashboard`: Includes `"forensic_trace": {...}`
