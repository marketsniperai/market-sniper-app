[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$CLOUD_RUN_URL = $env:CLOUD_RUN_URL,

    [Parameter(Mandatory=$false)]
    [string]$FOUNDER_KEY = $env:FOUNDER_KEY
)

# Defaults for Local Testing if not provided
if (-not $CLOUD_RUN_URL) {
    $CLOUD_RUN_URL = "http://localhost:8081"
    Write-Host "[INFO] No CLOUD_RUN_URL provided. Defaulting to $CLOUD_RUN_URL (Local Simulation)" -ForegroundColor Yellow
}

if (-not $FOUNDER_KEY) {
    Write-Host "[ERROR] FOUNDER_KEY is required. Set env var or pass argument." -ForegroundColor Red
    exit 1
}

# Redact Key for Logs (First 3 + Last 3)
$KEY_DISPLAY = "HIDDEN"
if ($FOUNDER_KEY.Length -gt 6) {
    $KEY_DISPLAY = $FOUNDER_KEY.Substring(0,3) + "****" + $FOUNDER_KEY.Substring($FOUNDER_KEY.Length-3)
}

Write-Host "`n=== CLOUD RUN SMOKE TEST (D56.01.9) ==="
Write-Host "Target: $CLOUD_RUN_URL"
Write-Host "Key:    $KEY_DISPLAY"
Write-Host "========================================`n"

$ErrorActionPreference = "Stop"

function Assert-Status {
    param($Response, $ExpectedCode, $Name)
    if ($Response.StatusCode -ne $ExpectedCode) {
        Write-Host "[FAIL] $Name returned $($Response.StatusCode) (Expected $ExpectedCode)" -ForegroundColor Red
        exit 1
    }
    Write-Host "[PASS] $Name -> $($Response.StatusCode)" -ForegroundColor Green
}

function Assert-Json {
    param($Content, $Field, $ExpectedValue, $Name)
    $actual = $Content | Select-Object -ExpandProperty $Field -ErrorAction SilentlyContinue
    if ($actual -ne $ExpectedValue) {
        Write-Host "[FAIL] $Name - field '$Field' was '$actual' (Expected '$ExpectedValue')" -ForegroundColor Red
        exit 1
    }
    Write-Host "[PASS] $Name verified '$Field' == '$ExpectedValue'" -ForegroundColor Green
}

# 1. Health Probe (PROBE FIX: Use /lab/healthz to bypass Edge 404)
try {
    $r = Invoke-WebRequest -Uri "$CLOUD_RUN_URL/lab/healthz" -Method Get -ErrorAction Stop
    Assert-Status $r 200 "GET /lab/healthz"
    $json = $r.Content | ConvertFrom-Json
    if ($json.status -ne "ALIVE") { throw "Status not ALIVE" }
    Write-Host "[PASS] /lab/healthz JSON payload OK" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] /lab/healthz check failed: $_" -ForegroundColor Red
    exit 1
}

# 2. Readiness Probe (PROBE FIX: Use /lab/readyz)
try {
    $r = Invoke-WebRequest -Uri "$CLOUD_RUN_URL/lab/readyz" -Method Get -ErrorAction Stop
    Assert-Status $r 200 "GET /lab/readyz"
    $json = $r.Content | ConvertFrom-Json
    if ($json.status -ne "READY") { throw "Status not READY" }
    Write-Host "[PASS] /lab/readyz JSON payload OK" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] /lab/readyz check failed: $_" -ForegroundColor Red
    exit 1
}

# 3. Snapshot (Unauthorized)
try {
    $r = Invoke-WebRequest -Uri "$CLOUD_RUN_URL/lab/war_room/snapshot" -Method Get -ErrorAction Stop
    Write-Host "[FAIL] Snapshot should have returned 403, but got $($r.StatusCode)" -ForegroundColor Red
    exit 1
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "[PASS] GET /lab/war_room/snapshot (No Key) -> 403 Forbidden" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Expected 403, got $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        exit 1
    }
}

# 4. Snapshot (Authorized)
try {
    $headers = @{ "X-Founder-Key" = $FOUNDER_KEY }
    $r = Invoke-WebRequest -Uri "$CLOUD_RUN_URL/lab/war_room/snapshot" -Method Get -Headers $headers -ErrorAction Stop
    Assert-Status $r 200 "GET /lab/war_room/snapshot (With Key)"
    
    $snap = $r.Content | ConvertFrom-Json
    
    # Check Meta
    if ($snap.meta.contract_version -ne "USP-1") { throw "Invalid contract_version: $($snap.meta.contract_version)" }
    if ($snap.meta.missing_modules.Count -ne 0) { throw "missing_modules is NOT EMPTY: $($snap.meta.missing_modules)" }
    
    Write-Host "[PASS] Snapshot Meta Checks (USP-1, Empty Missing Modules)" -ForegroundColor Green
    
    # Check Required Keys (Approximate check against hardcoded list or just count)
    # The list is in Python contract, difficult to import directly here without python call.
    # We will verify count >= 21 and presence of "canon_debt_radar"
    
    $keys = $snap.modules | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    if ($keys.Count -lt 21) {
        Write-Host "[FAIL] Too few module keys: $($keys.Count) (Expected >= 21)" -ForegroundColor Red
        exit 1
    }
    
    if ("canon_debt_radar" -notin $keys) {
        Write-Host "[FAIL] 'canon_debt_radar' missing from snapshot!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[PASS] Module Keys Count ($($keys.Count)) >= 21" -ForegroundColor Green
    
} catch {
    Write-Host "[FAIL] Authorized Snapshot Check Failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ SMOKE TEST PASSED" -ForegroundColor Green
exit 0
