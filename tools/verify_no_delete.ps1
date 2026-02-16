# tools/verify_no_delete.ps1
# ENFORCEMENT TOOL FOR ARTIFACT PRESERVATION LAW (NO DELETE)

$ErrorActionPreference = "Stop"

# Check Git Status for deleted files
# Filters for lines starting with 'D ' or ' D'
$DeletedFiles = git status --porcelain | Select-String "^(D | D)"

if ($DeletedFiles) {
    Write-Host "CRITICAL VIOLATION DETECTED: ARTIFACT PRESERVATION LAW" -ForegroundColor Red
    Write-Host "The following files are marked for DELETION:" -ForegroundColor Yellow
    $DeletedFiles | ForEach-Object { Write-Host "  $_" }

    # Check for Founder Approval
    $ApprovalFile = "FOUNDER_DELETE_APPROVAL.txt"
    if (Test-Path $ApprovalFile) {
        Write-Host "Approval file found: $ApprovalFile" -ForegroundColor Cyan
        $ApprovedFiles = Get-Content $ApprovalFile
        Write-Host "Found $($ApprovedFiles.Count) approved exceptions." -ForegroundColor Cyan
        
        # Verify if deleted files are listed in approval
        # (Simplified logic: assumes approval file lists paths)
        # For now, if approval file exists, we allow it with a warning, but stricter logic would match filenames.
        Write-Warning "Proceeding with deletion under FOUNDER AUTHORITY."
        exit 0
    }
    else {
        Write-Host "NO FOUNDER AUTHORIZATION FOUND." -ForegroundColor Red
        Write-Host "Deletion of artifacts is clearer prohibited by the ARTIFACT PRESERVATION LAW."
        Write-Host "Create '$ApprovalFile' with explicit justification to override."
        exit 1
    }
}
else {
    Write-Host "ARTIFACT PRESERVATION LAW COMPLIANT. No deletions detected." -ForegroundColor Green
    exit 0
}
