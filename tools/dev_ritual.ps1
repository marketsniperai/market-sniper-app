# D56.01.4 Dev Ritual Hardening - "Verified State Machine"
# Guarantees Backend is listening on :8000 with the correct Founder Key before launching Flutter.

$ErrorActionPreference = "Stop"

function Get-Timestamp { return Get-Date -Format "HH:mm:ss" }
function Log-Info ($msg) { Write-Host "[$((Get-Timestamp))] [INFO] $msg" -ForegroundColor Cyan }
function Log-Pass ($msg) { Write-Host "[$((Get-Timestamp))] [PASS] $msg" -ForegroundColor Green }
function Log-Warn ($msg) { Write-Host "[$((Get-Timestamp))] [WARN] $msg" -ForegroundColor Yellow }
function Log-Fail ($msg) { Write-Host "[$((Get-Timestamp))] [FAIL] $msg" -ForegroundColor Red }

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   MARKETSNIPER OS - DEV RITUAL (D56)" -ForegroundColor Cyan
Write-Host "   Target: Localhost (Web)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Resolve Founder Key
# Priority: Env -> .env.local -> Default
$founderKey = $env:FOUNDER_KEY
$repoRoot = Resolve-Path "$PSScriptRoot\.."
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
$listener = $null

try {
    $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
} catch {}

if ($listener) {
    Log-Info "Port $port is active (PID: $($listener.OwningProcess)). Verifying session..."
    
    # PROBE: Verified Skip Check
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:8000/lab/war_room/snapshot" `
            -Headers @{ "X-Founder-Key" = $founderKey } `
            -Method Get `
            -ErrorAction Stop `
            -TimeoutSec 2
            
        if ($resp.StatusCode -eq 200) {
            Log-Pass "Backend verified (200 OK). Skipping verified start."
            $needsStart = $false
        } else {
            throw "Status $($resp.StatusCode)"
        }
    } catch {
        Log-Warn "Drift Detected or Probe Failed ($($_.Exception.Message))."
        Log-Warn "Killing PID $($listener.OwningProcess) to restore truth..."
        Stop-Process -Id $listener.OwningProcess -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

# 3. Start Backend if Needed
if ($needsStart) {
    Log-Info "Starting Backend on Port $port..."
    
    # Prepare Command with Explicit Env Injection
    # Using 'py' as per standard environment
    $cmd = [string]::Format(
        "`$env:FOUNDER_BUILD='1'; `$env:FOUNDER_KEY='{0}'; py -m uvicorn backend.api_server:app --host localhost --port {1} --reload",
        $founderKey, $port
    )
    
    Start-Process powershell -WorkingDirectory $repoRoot -ArgumentList "-NoExit", "-Command", $cmd
    
    # Liveness Loop (Hard Gate)
    Log-Info "Waiting for Backend Pulse (up to 5s)..."
    $maxRetries = 20
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
        Log-Fail "Backend failed to stabilize. Check the other terminal window for errors."
        exit 1
    }
    
    Log-Pass "Backend Live & Verified."
}

# 4. Education Banner
Write-Host ""
Write-Host "[HINT] To verify backend manually: netstat -ano | findstr `":$port`"" -ForegroundColor Gray
Write-Host ""

# 5. Launch Flutter
Log-Info "Launching Flutter Web..."
Set-Location "$repoRoot\market_sniper_app"

# Invoke Flutter with same Key
$flutterArgs = "run -d chrome --web-port=5000 --dart-define=FOUNDER_API_KEY=$founderKey --dart-define=FOUNDER_BUILD=true"
Invoke-Expression "flutter $flutterArgs"

Log-Pass "Ritual Complete."
