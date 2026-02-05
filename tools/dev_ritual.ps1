# D56.01.6 War Room Green Hard Gate
# Guarantees Backend is listening on :8000 with the correct Founder Key and proven Liveness.

$ErrorActionPreference = "Stop"

function Get-Timestamp { return Get-Date -Format "HH:mm:ss" }
function Log-Info ($msg) { Write-Host "[$((Get-Timestamp))] [INFO] $msg" -ForegroundColor Cyan }
function Log-Pass ($msg) { Write-Host "[$((Get-Timestamp))] [PASS] $msg" -ForegroundColor Green }
function Log-Warn ($msg) { Write-Host "[$((Get-Timestamp))] [WARN] $msg" -ForegroundColor Yellow }
function Log-Fail ($msg) { Write-Host "[$((Get-Timestamp))] [FAIL] $msg" -ForegroundColor Red }

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   MARKETSNIPER OS - DEV RITUAL (D56)" -ForegroundColor Cyan
Write-Host "   Green Hard Gate Edition" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 2.1 Repo Root Fix
# Always start from repo root regardless of caller working directory
Set-Location (Join-Path $PSScriptRoot "..")
$repoRoot = Get-Location
Log-Info "Working Root: $repoRoot"

# 1. Resolve Founder Key
# Priority: Env -> .env.local -> Default
$founderKey = $env:FOUNDER_KEY
$envFile = Join-Path $repoRoot ".env.local"

if (-not $founderKey -and (Test-Path $envFile)) {
    Log-Info "Reading FOUNDER_KEY from .env.local..."
    $lines = Get-Content $envFile
    foreach ($line in $lines) {
        if ($line -match "^FOUNDER_KEY=(.+)$") {
            $founderKey = $matches[1].Trim()
            break
        }
    }
}

if (-not $founderKey) {
    Log-Warn "No key found. Using default Verified Debug Key."
    $founderKey = "mz_founder_888"
}

Log-Pass "Key Context Resolved: $founderKey"

# 2. Check Backend State
$port = 8000
$needsStart = $true
$pidFound = $null

# 2.2 Identify Listener Reliably
try {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $pidFound = $conn.OwningProcess
    }
} catch {}

if ($pidFound) {
    Log-Info "Port $port is active (PID: $pidFound). Verifying session..."
    
    # 2.3 Verified Probe (Key + HTTP 200)
    try {
        # Using curl (if available) or Invoke-WebRequest as fallback
        # User requested curl command style: curl -s -o $null -w "%{http_code}" ...
        # But in PowerShell, Invoke-WebRequest is safer/native. 
        # I will use Invoke-WebRequest but strictly check 200.
        
        $resp = Invoke-WebRequest -Uri "http://localhost:8000/lab/war_room/snapshot" `
            -Headers @{ "X-Founder-Key" = $founderKey } `
            -Method Get `
            -ErrorAction Stop `
            -TimeoutSec 2
            
        if ($resp.StatusCode -eq 200) {
            Log-Pass "Backend verified (200 OK). VERIFIED SKIP."
            $needsStart = $false
        } else {
            throw "Status $($resp.StatusCode)"
        }
    } catch {
        Log-Warn "DRIFT / DEAD / WRONG PROCESS DETECTED ($($_.Exception.Message))."
        
        # 2.4 Kill (Surgical)
        Log-Warn "Killing PID $pidFound to restore truth..."
        Stop-Process -Id $pidFound -Force -ErrorAction SilentlyContinue
        
        # Wait for port release
        Start-Sleep -Seconds 2
        
        # Verify killed
        $stillThere = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($stillThere) {
             Log-Fail "Port $port is still locked by PID $($stillThere.OwningProcess). Manual intervention required."
             exit 1
        }
        Log-Pass "Port Freed."
    }
}

# 3. Start Backend with 2.5 Explicit Env Injection
if ($needsStart) {
    Log-Info "Starting Backend on Port $port (Clean Process)..."
    
    # Construct Explicit Command (No Inheritance Assumptions)
    # Using 'py' as per standard environment. 
    # NOTE: PowerShell inside Start-Process argument list handles definitions.
    
    $cmd = [string]::Format(
        "`$env:FOUNDER_BUILD='1'; `$env:FOUNDER_KEY='{0}'; py -m uvicorn backend.api_server:app --host localhost --port {1} --reload",
        $founderKey, $port
    )
    
    Start-Process powershell -WorkingDirectory $repoRoot -ArgumentList "-NoExit", "-Command", $cmd
    
    # 2.6 Liveness Loop (Hard Gate)
    Log-Info "Waiting for Backend Pulse (Hard Gate)..."
    $maxRetries = 40 # 10s total
    $health = $false
    
    for ($i=1; $i -le $maxRetries; $i++) {
        Start-Sleep -Milliseconds 250
        try {
            $resp = Invoke-WebRequest -Uri "http://localhost:8000/lab/war_room/snapshot" `
                -Headers @{ "X-Founder-Key" = $founderKey } `
                -Method Get `
                -ErrorAction SilentlyContinue `
                -TimeoutSec 1
                
            if ($resp.StatusCode -eq 200) {
                $health = $true
                break
            }
        } catch {}
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    Write-Host "" 
    
    if (-not $health) {
        Log-Fail "Backend failed to stabilize (Timeout 10s)."
        Log-Fail "Outcome: HARD GATE CLOSED. Flutter will not launch."
        exit 1
    }
    
    Log-Pass "Backend Live & Verified (200 OK)."
}

# 2.7 Education Banner
Write-Host ""
Write-Host "   EDUCATION & DIAGNOSTICS" -ForegroundColor Gray
Write-Host "   netstat -ano | findstr `":$port`"" -ForegroundColor Gray
Write-Host "   Get-NetTCPConnection -LocalPort $port -State Listen" -ForegroundColor Gray
Write-Host "   curl -H `"X-Founder-Key: ...`" http://localhost:8000/lab/war_room/snapshot" -ForegroundColor Gray
Write-Host ""

# 3. BASE URL INTEGRITY via 3.1 Explicit Build Profile Switch
$apiBaseUrl = "http://localhost:8000"

# 5. Launch Flutter
Log-Info "Launching Flutter Web with Green Hard Gate passed..."
Set-Location (Join-Path $repoRoot "market_sniper_app")

# Invoke Flutter with Key AND Explicit API_BASE_URL
# Added --dart-define=API_BASE_URL=$apiBaseUrl
# Added --dart-define=NET_AUDIT_ENABLED=true for visibility
$flutterArgs = "run -d chrome --web-port=5000 --dart-define=FOUNDER_API_KEY=$founderKey --dart-define=FOUNDER_BUILD=true --dart-define=API_BASE_URL=$apiBaseUrl --dart-define=NET_AUDIT_ENABLED=true"
Invoke-Expression "flutter $flutterArgs"

Log-Pass "Ritual Complete."
