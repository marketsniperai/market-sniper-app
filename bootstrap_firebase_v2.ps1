$PROJECT_ID = "marketsniper-intel-osr-9953"
$token = gcloud auth print-access-token
Write-Host "Checking Firebase Project Status..."
$headers = @{ Authorization = "Bearer $token" }

function Get-Http-Error-Details($ex) {
    if ($ex.Response) {
        $r = $ex.Response
        Write-Host "HTTP_STATUS=$($r.StatusCode.value__)"
        try {
            $stream = $r.GetResponseStream()
            if ($stream) {
                $reader = New-Object System.IO.StreamReader($stream)
                $body = $reader.ReadToEnd()
                Write-Host "BODY=$body"
            }
        }
        catch {
            Write-Host "Could not read error body."
        }
    }
    else {
        Write-Host "NO_RESPONSE_OBJECT"
    }
}

try {
    $resp = Invoke-WebRequest -Uri "https://firebase.googleapis.com/v1beta1/projects/$PROJECT_ID" -Headers $headers -Method GET -UseBasicParsing
    Write-Host "FIREBASE_PROJECT_GET_STATUS=$($resp.StatusCode)"
}
catch {
    Write-Host "FIREBASE_PROJECT_GET_FAILED"
    Write-Host $_.Exception.Message
    Get-Http-Error-Details $_.Exception
  
    # Logic: If 404/403, try Add
    # BUT parsing statuscode from complex object in shell is hard.
    # We'll just unconditionaly try ADD if GET failed, letting the API return 409 if exists.
  
    Write-Host "Attempting to register Firebase Project (Blind)..."
    $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    try {
        $resp = Invoke-WebRequest -Uri "https://firebase.googleapis.com/v1beta1/projects/$PROJECT_ID:addFirebase" -Headers $headers -Method POST -Body '{}' -UseBasicParsing
        Write-Host "ADD_FIREBASE_STATUS=$($resp.StatusCode)"
    }
    catch {
        Write-Host "ADD_FIREBASE_FAILED"
        Write-Host $_.Exception.Message
        Get-Http-Error-Details $_.Exception
    }
}
