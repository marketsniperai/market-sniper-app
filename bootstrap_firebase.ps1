$PROJECT_ID = "marketsniper-intel-osr-9953"
$token = gcloud auth print-access-token

Write-Host "Checking Firebase Project Status..."
$headers = @{ Authorization = "Bearer $token" }

try {
    $resp = Invoke-WebRequest -Uri "https://firebase.googleapis.com/v1beta1/projects/$PROJECT_ID" -Headers $headers -Method GET -UseBasicParsing
    Write-Host "FIREBASE_PROJECT_GET_STATUS=$($resp.StatusCode)"
    $resp.Content
}
catch {
    Write-Host "FIREBASE_PROJECT_GET_FAILED"
    Write-Host $_.Exception.Message
    if ($_.Exception.Response) {
        $r = $_.Exception.Response
        Write-Host "HTTP_STATUS=$($r.StatusCode.value__)"
    
        if ($r.StatusCode.value__ -eq 404 -or $r.StatusCode.value__ -eq 403) {
            Write-Host "Attempting to register Firebase Project..."
            $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
            try {
                $resp = Invoke-WebRequest -Uri "https://firebase.googleapis.com/v1beta1/projects/$PROJECT_ID:addFirebase" -Headers $headers -Method POST -Body '{}' -UseBasicParsing
                Write-Host "ADD_FIREBASE_STATUS=$($resp.StatusCode)"
                $resp.Content
            }
            catch {
                Write-Host "ADD_FIREBASE_FAILED"
                Write-Host $_.Exception.Message
                if ($_.Exception.Response) {
                    $r = $_.Exception.Response
                    Write-Host "HTTP_STATUS=$($r.StatusCode.value__)"
                    # Print body for details
                    $stream = $r.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($stream)
                    $body = $reader.ReadToEnd()
                    Write-Host "ERROR_BODY=$body"
                }
            }
        }
    }
}
