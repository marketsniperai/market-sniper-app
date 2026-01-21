# Cleanup Debug Artifacts
# Generated for D45.H1 Stabilization

$patterns = @(
    "market_sniper_app/analysis*.txt",
    "market_sniper_app/analyze_output*.txt",
    "market_sniper_app/build_log.txt",
    "market_sniper_app/status_check.txt",
    "market_sniper_app/analysis_build.txt"
)

foreach ($pattern in $patterns) {
    if (Test-Path $pattern) {
        Remove-Item $pattern -Force -ErrorAction SilentlyContinue
        Write-Host "Removed: $pattern"
    }
}
Write-Host "Cleanup Complete."
