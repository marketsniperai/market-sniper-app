# tools/verify_snapshot_only.ps1
# ENFORCEMENT TOOL FOR SNAPSHOT-FIRST UI LAW

$ErrorActionPreference = "Stop"

$RootDir = Join-Path $PSScriptRoot "..\market_sniper_app"
$ScanDirs = @(
    "lib\screens",
    "lib\widgets",
    "lib\logic"
)

$ForbiddenPatterns = @(
    @{ Pattern = "import .*api_client.dart"; Description = "Direct ApiClient Import in UI" },
    @{ Pattern = "client\.get\("; Description = "Direct HTTP GET" },
    @{ Pattern = "client\.post\("; Description = "Direct HTTP POST" },
    @{ Pattern = "http\."; Description = "Direct HTTP Usage" },
    @{ Pattern = "dio\."; Description = "Direct Dio Usage" },
    @{ Pattern = "'/dashboard'"; Description = "Legacy Dashboard Endpoint String" },
    @{ Pattern = "'/misfire'"; Description = "Legacy Misfire Endpoint String" }
)

$Violations = 0

Write-Host "SNAPSHOT-FIRST LAW ENFORCEMENT SCAN" -ForegroundColor Cyan
Write-Host "Scanning UI directories for network violations..."

foreach ($Dir in $ScanDirs) {
    $FullPath = Join-Path $RootDir $Dir
    if (-not (Test-Path $FullPath)) {
        Write-Warning "Directory not found: $FullPath"
        continue
    }

    $Files = Get-ChildItem -Path $FullPath -Recurse -Filter "*.dart"

    foreach ($File in $Files) {
        $Content = Get-Content $File.FullName
        
        foreach ($Rule in $ForbiddenPatterns) {
            if ($Content | Select-String -Pattern $Rule.Pattern -Quiet) {
                # Verify it's not a comment? (Simple check, not robust parser)
                # For now, strict: even in comments, avoid if possible, or we assume active code.
                # Actually, Select-String regex is robust enough for now.
                
                Write-Host "VIOLATION DETECTED in $($File.Name)" -ForegroundColor Red
                Write-Host "  Rule: $($Rule.Description)" -ForegroundColor Yellow
                Write-Host "  Pattern: $($Rule.Pattern)"
                Write-Host "  File: $($File.FullName)"
                $Violations++
            }
        }
    }
}

if ($Violations -gt 0) {
    Write-Host "SNAPSHOT-FIRST LAW VIOLATION: $Violations forbidden patterns found." -ForegroundColor Red
    Write-Host "UI must use UnifiedSnapshotRepository. Network calls in screens/widgets are BANNED."
    exit 1
}
else {
    Write-Host "SNAPSHOT-FIRST LAW COMPLIANT. Zero violations found." -ForegroundColor Green
    exit 0
}
