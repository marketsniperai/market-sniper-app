# Deploy Market Sniper Auth Gateway (Org Policy Bypass)
# Robust V2

$ErrorActionPreference = "Stop"
$PROJECT_ID = "marketsniper-intel-osr-9953"
$REGION = "us-central1"
$SA_EMAIL = "ms-api-gateway-invoker@marketsniper-intel-osr-9953.iam.gserviceaccount.com"
$SCRIPT_DIR = $PSScriptRoot
$OPENAPI_SPEC = Join-Path -Path $SCRIPT_DIR -ChildPath "..\..\openapi.yaml"
# Resolve absolute path to avoid relative path issues if CWD varies
$OPENAPI_SPEC_ABS = (Resolve-Path $OPENAPI_SPEC).Path

Write-Host "Context: Project=$PROJECT_ID, Region=$REGION"
Write-Host "Spec: $OPENAPI_SPEC_ABS"

# 1. API Resource
Write-Host "1. Checking/Creating API Resource..."
$apiExists = gcloud api-gateway apis list --project=$PROJECT_ID --filter="name:ms-gateway-api" --format="value(name)"
if (-not $apiExists) {
    gcloud api-gateway apis create ms-gateway-api --project=$PROJECT_ID
}
else {
    Write-Host "   API Resource already exists."
}

# 2. Config
Write-Host "2. Creating API Config (ms-config-v2)..."
# We use a timestamped or incremental ID to avoid conflict if v1 failed or exists
$CONFIG_ID = "ms-config-v" + (Get-Date -Format "yyyyMMdd-HHmm")
gcloud api-gateway api-configs create $CONFIG_ID --api=ms-gateway-api --openapi-spec=$OPENAPI_SPEC_ABS --project=$PROJECT_ID --backend-auth-service-account=$SA_EMAIL

# 3. Gateway
Write-Host "3. Creating/Updating Gateway (ms-gateway)..."
$gwExists = gcloud api-gateway gateways list --location=$REGION --project=$PROJECT_ID --filter="name:ms-gateway" --format="value(name)"
if (-not $gwExists) {
    gcloud api-gateway gateways create ms-gateway --api=ms-gateway-api --api-config=$CONFIG_ID --location=$REGION --project=$PROJECT_ID
}
else {
    Write-Host "   Gateway exists, updating config..."
    gcloud api-gateway gateways update ms-gateway --api=ms-gateway-api --api-config=$CONFIG_ID --location=$REGION --project=$PROJECT_ID
}

# 4. API Key
Write-Host "4. Checking/Creating API Key..."
$KEY_NAME = "Market Sniper Founder Key"
$keyId = gcloud beta services api-keys list --project=$PROJECT_ID --filter="displayName:`"$KEY_NAME`"" --format="value(name)"

if (-not $keyId) {
    gcloud beta services api-keys create --display-name="$KEY_NAME" --project=$PROJECT_ID
    # Fetch again to get ID/String
    $keydata = gcloud beta services api-keys list --project=$PROJECT_ID --filter="displayName:`"$KEY_NAME`"" --format="json" | ConvertFrom-Json
}
else {
    Write-Host "   API Key exists."
    $keydata = gcloud beta services api-keys list --project=$PROJECT_ID --filter="displayName:`"$KEY_NAME`"" --format="json" | ConvertFrom-Json
}

# 5. Capture Outputs
$GATEWAY_URL = gcloud api-gateway gateways describe ms-gateway --location=$REGION --project=$PROJECT_ID --format="value(defaultHostname)"
$API_KEY = $keydata.keyString

Write-Host "---------------------------------------------------"
Write-Host "DEPLOYMENT COMPLETE"
Write-Host "GATEWAY_HOST: $GATEWAY_URL"
# Redact for logs, but keep accessible for Agent reading if needed via file
Write-Host "FOUNDER_API_KEY: (Ends with) ...$($API_KEY.Substring($API_KEY.Length - 4))"
Write-Host "---------------------------------------------------"

# Save unredacted to a secret file for Agent to read (Agent only)
$OUTPUT_FILE = Join-Path -Path $SCRIPT_DIR -ChildPath "..\proofs\day45_hf08_auth_gateway\DEPLOY_SECRETS.json"
$out = @{
    API_GATEWAY_URL = "https://$GATEWAY_URL"
    FOUNDER_API_KEY = $API_KEY
}
$out | ConvertTo-Json | Out-File -FilePath $OUTPUT_FILE -Encoding utf8
Write-Host "Secrets saved to $OUTPUT_FILE"
