
# D57.EWIMSC Single Harness Orchestrator

$ErrorActionPreference = "Stop"

$ROOT_DIR = Get-Location
$OUTPUT_DIR = "$ROOT_DIR/outputs/proofs/D57_EWIMSC_SINGLE_HARNESS"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"
$BOOT_LOG = "$OUTPUT_DIR/backend_boot_$TIMESTAMP.log"

# Clean previous
if (Test-Path $OUTPUT_DIR) { Remove-Item -Path $OUTPUT_DIR -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null

Write-Host "--- D57 EWIMSC SINGLE HARNESS ---"
Write-Host "Root: $ROOT_DIR"
Write-Host "Logs: $BOOT_LOG"

# 1. Find Port
$port = 8787
while ($true) {
    if (-not (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue)) {
        break
    }
    Write-Host "Port $port busy, trying next..."
    $port++
    if ($port -gt 8800) {
        Write-Error "Could not find free port in range 8787-8800"
        exit 1
    }
}
Write-Host "Selected Port: $port"

# 2. Boot Backend
Write-Host "Booting Backend..."
$env:PORT = $port
$env:ENV = "local"
# Using uvicorn directly assuming python is available as 'py' or 'python'
# We'll use 'py -m uvicorn' to be safe with user's alias preference
# Using cmd /c to handle redirection to file directly (Non-blocking IO)
$procInfo = New-Object System.Diagnostics.ProcessStartInfo
$procInfo.FileName = "cmd"
$procInfo.Arguments = "/c py -m uvicorn backend.api_server:app --host 127.0.0.1 --port $port > ""$BOOT_LOG"" 2>&1"
$procInfo.RedirectStandardOutput = $false
$procInfo.RedirectStandardError = $false
$procInfo.UseShellExecute = $false
$procInfo.CreateNoWindow = $true

$backendProcess = [System.Diagnostics.Process]::Start($procInfo)

# Log capture handled by shell redirection
Start-Sleep -Milliseconds 500

# 3. Wait for Readiness
$url = "http://127.0.0.1:$port"
$maxRetries = 30
$retryCount = 0
$backendReady = $false

while ($retryCount -lt $maxRetries) {
    try {
        $resp = Invoke-WebRequest -Uri "$url/lab/healthz" -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            $backendReady = $true
            Write-Host "Backend READY!"
            break
        }
    }
    catch {
        Start-Sleep -Milliseconds 1000
        Write-Host -NoNewline "."
        $retryCount++
    }
}

if (-not $backendReady) {
    Write-Host "`nFATAL: Backend did not boot in time."
    Stop-Process -Id $backendProcess.Id -Force
    exit 1
}

# 4. Zombie Scan (Triage Mode) - Runs BEFORE Harness to generate report
Write-Host "--- RUNNING ZOMBIE SCAN (TRIAGE MODE) ---"
try {
    $scanOut = "$OUTPUT_DIR/../D57_5_ZOMBIE_TRIAGE"
    New-Item -ItemType Directory -Force -Path $scanOut | Out-Null
    
    py tools/ewimsc/ewimsc_zombie_scan.py --out $scanOut
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Zombie Triage Completed. Running Regression Gate..."
        $baseline = "docs/canon/UNKNOWN_BASELINE.json"
        if (-not (Test-Path $baseline)) {
            Write-Error "Baseline Missing: $baseline"
            exit 1 
        }
        
        py tools/ewimsc/ewimsc_unknown_gate.py --baseline $baseline --report "$scanOut/zombie_report.json" --out "$scanOut/unknown_gate_report.json"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FATAL: UNKNOWN_ZOMBIE REGRESSION DETECTED"
            Stop-Process -Id $backendProcess.Id -Force
            exit 1
        }

        # D58.6 Weekly Trend Gate
        Write-Host "Running Weekly Trend Gate..."
        py tools/ewimsc/ewimsc_unknown_weekly_gate.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FATAL: WEEKLY UNKNOWN TREND GATE FAILED"
            Stop-Process -Id $backendProcess.Id -Force
            exit 1
        }

        # D58.X Release Zero Gate
        Write-Host "Running Release Zero Gate..."
        py tools/ewimsc/ewimsc_release_unknown_zero_gate.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FATAL: RELEASE MODE BLOCKED (UNKNOWN > 0)"
            Stop-Process -Id $backendProcess.Id -Force
            exit 1
        }
    }
    else {
        Write-Host "WARNING: Zombie Scan Failed (Non-Blocking)"
    }
}
catch {
    Write-Host "WARNING: Zombie Scan Exception: $_"
}

Write-Host "Backend UP! Running Verifier..."

$harnessExit = 0
try {
    # 5. Run Harness (Consumes Zombie Report)
    try {
        # Using the standard proof dir for harness output
        py tools/ewimsc/ewimsc_core_harness.py --url $url --out $OUTPUT_DIR --suite all
        if ($LASTEXITCODE -ne 0) { $harnessExit = 1 }
    }
    catch {
        Write-Host "Harness Exception: $_"
        $harnessExit = 2
    }
}
finally {
    # 6. Elite Negative Suite (D58.5)
    try {
        Write-Host "Running Elite Negative Suite..."
        py tools/ewimsc/ewimsc_elite_negative_suite.py --port $port
        if ($LASTEXITCODE -ne 0) { 
            Write-Error "Elite Negative Suite FAILED"
            $harnessExit = 1 
        }
    }
    catch {
        Write-Host "Elite Suite Exception: $_"
        $harnessExit = 2
    }
    
    # 7. Cleanup
    Write-Host "Stopping Backend..."
    Stop-Process -Id $backendProcess.Id -Force
    Write-Host "Done."

    # Hardening: Ensure VERDICT exists if harness crashed before writing it
    $VERDICT_FILE = "$OUTPUT_DIR/VERDICT.txt"
    if (-not (Test-Path $VERDICT_FILE)) {
        "FAIL: HARNESS_CRASHED_NO_VERDICT" | Out-File $VERDICT_FILE -Encoding utf8
        if ($harnessExit -eq 0) { $harnessExit = 2 }
    }
}

exit $harnessExit
