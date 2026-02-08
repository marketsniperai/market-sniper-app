
# D57.1 EWIMSC CI WRAPPER (Full Steel)
# Deterministic wrapper for CI execution.

$ErrorActionPreference = "Stop"

# 1. Resolve Root (Robust)
$SCRIPT_DIR = $PSScriptRoot
$ROOT_DIR = (Resolve-Path "$SCRIPT_DIR/../..").Path

Write-Host "--- EWIMSC CI WRAPPER ---"
Write-Host "Script Dir: $SCRIPT_DIR"
Write-Host "Root Dir:   $ROOT_DIR"

Set-Location -Path $ROOT_DIR

# 2. Invoke Harness (Pass-Thru)
$HARNESS_SCRIPT = "$ROOT_DIR/tools/ewimsc/ewimsc_run.ps1"
Write-Host "Invoking: $HARNESS_SCRIPT"

$exitCode = 0
try {
    # Use Invoke-Expression or & operator. & is safer.
    & $HARNESS_SCRIPT
    $exitCode = $LASTEXITCODE
}
catch {
    Write-Host "CI Wrapper Exception: $_"
    $exitCode = 2
}

# 3. Verify Artifacts (Gate)
$PROOF_DIR = "$ROOT_DIR/outputs/proofs/D57_EWIMSC_SINGLE_HARNESS"
$REPORT_FILE = "$PROOF_DIR/core_report.json"
$NEG_REPORT_FILE = "$PROOF_DIR/negative_report.json"
$CONTRACT_REPORT_FILE = "$PROOF_DIR/contract_report.json"
$VERDICT_FILE = "$PROOF_DIR/VERDICT.txt"

Write-Host "--- CI ARTIFACT CHECK ---"
if (-not (Test-Path $REPORT_FILE)) {
    Write-Host "FATAL: core_report.json MISSING"
    if ($exitCode -eq 0) { $exitCode = 2 } # Force fail if output missing
}
else {
    Write-Host "FOUND: core_report.json"
}

if (-not (Test-Path $NEG_REPORT_FILE)) {
    Write-Host "FATAL: negative_report.json MISSING"
    if ($exitCode -eq 0) { $exitCode = 2 }
}
else {
    Write-Host "FOUND: negative_report.json"
}

if (-not (Test-Path $CONTRACT_REPORT_FILE)) {
    Write-Host "FATAL: contract_report.json MISSING"
    if ($exitCode -eq 0) { $exitCode = 2 }
}
else {
    Write-Host "FOUND: contract_report.json"
}

$LAB_REPORT_FILE = Join-Path $PROOF_DIR "lab_internal_report.json"
if (-not (Test-Path $LAB_REPORT_FILE)) {
    Write-Host "FATAL: lab_internal_report.json MISSING (Security Check skipped?)"
    if ($exitCode -eq 0) { $exitCode = 2 }
}
else {
    Write-Host "FOUND: lab_internal_report.json (Full Steel)"
}

$GATE_REPORT_FILE = "$ROOT_DIR/outputs/proofs/D57_5_ZOMBIE_TRIAGE/unknown_gate_report.json"
if (-not (Test-Path $GATE_REPORT_FILE)) {
    Write-Host "FATAL: unknown_gate_report.json MISSING"
    if ($exitCode -eq 0) { $exitCode = 2 }
}
else {
    Write-Host "FOUND: unknown_gate_report.json (Regression Gate)"
}

$WEEKLY_GATE_REPORT = "$ROOT_DIR/outputs/proofs/D58_6_UNKNOWN_TREND/unknown_weekly_gate_report.json"
if (-not (Test-Path $WEEKLY_GATE_REPORT)) {
    Write-Host "FATAL: unknown_weekly_gate_report.json MISSING"
    if ($exitCode -eq 0) { $exitCode = 2 }
}
else {
    Write-Host "FOUND: unknown_weekly_gate_report.json (Weekly Trend)"
}

$RELEASE_GATE_REPORT = "$ROOT_DIR/outputs/proofs/D58_X_RELEASE_GATE/release_unknown_zero_gate_report.json"
if (-not (Test-Path $RELEASE_GATE_REPORT)) {
    Write-Host "FATAL: release_unknown_zero_gate_report.json MISSING"
    if ($exitCode -eq 0) { $exitCode = 2 }
}
else {
    Write-Host "FOUND: release_unknown_zero_gate_report.json"
}

if (-not (Test-Path $VERDICT_FILE)) {
    Write-Host "FATAL: VERDICT.txt MISSING"
    if ($exitCode -eq 0) { $exitCode = 2 }
}
else {
    $verdict = Get-Content $VERDICT_FILE -Raw
    Write-Host "VERDICT CONTENT:"
    Write-Host $verdict
    Write-Host "----------------"
}

Write-Host "CI FINAL EXIT CODE: $exitCode"
exit $exitCode
