#!/bin/bash
# D56.01.9 Smoke Test for Cloud Run (Bash/Curl/Python)
# Usage: ./smoke_cloud_run.sh

set -e

# 1. Inputs (Env Vars)
URL=${CLOUD_RUN_URL:-"http://localhost:8081"}
KEY=${FOUNDER_KEY}

# Redact Key for Logs
KEY_DISPLAY="HIDDEN"
if [ "${#KEY}" -gt 6 ]; then
  KEY_DISPLAY="${KEY:0:3}****${KEY: -3}"
fi

echo ""
echo "=== CLOUD RUN SMOKE TEST (BASH) ==="
echo "Target: $URL"
echo "Key:    $KEY_DISPLAY"
echo "==================================="
echo ""

if [ -z "$KEY" ]; then
  echo "[ERROR] FOUNDER_KEY env var is missing."
  exit 1
fi

# Helper function to check status code
check_status() {
  local code=$1
  local expected=$2
  local name=$3
  if [ "$code" -ne "$expected" ]; then
    echo "[FAIL] $name returned $code (Expected $expected)"
    exit 1
  else
    echo "[PASS] $name -> $code"
  fi
}

# Helper to parse JSON field using Python (avoid jq dependency)
get_json_field() {
  local json="$1"
  local field="$2"
  # Python one-liner to extract field from JSON string
  echo "$json" | python -c "import sys, json; print(json.load(sys.stdin).get('$field', ''))"
}

get_nested_field() {
  local json="$1"
  # Python script to extract meta.contract_version etc.
  echo "$json" | python -c "import sys, json; data=json.load(sys.stdin); print(data['meta']['contract_version'])"
}

check_missing_empty() {
    local json="$1"
    echo "$json" | python -c "import sys, json; data=json.load(sys.stdin); print(len(data['meta']['missing_modules']))"
}

check_modules_count() {
    local json="$1"
    echo "$json" | python -c "import sys, json; data=json.load(sys.stdin); print(len(data['modules']))"
}

has_module_key() {
    local json="$1"
    local key="$2"
    echo "$json" | python -c "import sys, json; data=json.load(sys.stdin); print('YES' if '$key' in data['modules'] else 'NO')"
}

# 1. Health Probe (PROBE FIX: Use /lab/healthz)
echo "--- CHECK: /lab/healthz ---"
HTTP_CODE=$(curl -s -o /tmp/healthz.json -w "%{http_code}" "$URL/lab/healthz")
check_status "$HTTP_CODE" 200 "GET /lab/healthz"
STATUS=$(cat /tmp/healthz.json | python -c "import sys, json; print(json.load(sys.stdin).get('status'))")
if [ "$STATUS" != "ALIVE" ]; then
  echo "[FAIL] /lab/healthz status is '$STATUS' (Expected ALIVE)"
  exit 1
fi
echo "[PASS] /lab/healthz JSON payload OK"

# 2. Readiness Probe (PROBE FIX: Use /lab/readyz)
echo "--- CHECK: /lab/readyz ---"
HTTP_CODE=$(curl -s -o /tmp/readyz.json -w "%{http_code}" "$URL/lab/readyz")
check_status "$HTTP_CODE" 200 "GET /lab/readyz"
STATUS=$(cat /tmp/readyz.json | python -c "import sys, json; print(json.load(sys.stdin).get('status'))")
if [ "$STATUS" != "READY" ]; then
  echo "[FAIL] /lab/readyz status is '$STATUS' (Expected READY)"
  exit 1
fi
echo "[PASS] /lab/readyz JSON payload OK"

# 3. Snapshot (Unauthorized)
echo "--- CHECK: /lab/war_room/snapshot (Unauthorized) ---"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL/lab/war_room/snapshot")
if [ "$HTTP_CODE" -eq 403 ] || [ "$HTTP_CODE" -eq 401 ]; then
  echo "[PASS] Unauthorized request -> $HTTP_CODE"
else
  echo "[FAIL] Expected 403/401, got $HTTP_CODE"
  exit 1
fi

# 4. Snapshot (Authorized)
echo "--- CHECK: /lab/war_room/snapshot (Authorized) ---"
HTTP_CODE=$(curl -s -H "X-Founder-Key: $KEY" -o /tmp/snapshot.json -w "%{http_code}" "$URL/lab/war_room/snapshot")
check_status "$HTTP_CODE" 200 "GET Snapshot"

# Validate Schema
SNAP=$(cat /tmp/snapshot.json)
CV=$(get_nested_field "$SNAP")
if [ "$CV" != "USP-1" ]; then
  echo "[FAIL] Invalid contract_version: $CV"
  exit 1
fi

MISSING_COUNT=$(check_missing_empty "$SNAP")
if [ "$MISSING_COUNT" -ne 0 ]; then
  echo "[FAIL] meta.missing_modules is NOT EMPTY (Count: $MISSING_COUNT)"
  exit 1
fi

MODULES_COUNT=$(check_modules_count "$SNAP")
if [ "$MODULES_COUNT" -lt 21 ]; then
  echo "[FAIL] Too few modules: $MODULES_COUNT (Expected >= 21)"
  exit 1
fi

HAS_RADAR=$(has_module_key "$SNAP" "canon_debt_radar")
if [ "$HAS_RADAR" != "YES" ]; then
  echo "[FAIL] 'canon_debt_radar' missing from modules"
  exit 1
fi

echo "[PASS] Snapshot Schema, Missing Modules [], and Key Checks"

echo ""
echo "✅ SMOKE TEST PASSED"
exit 0
