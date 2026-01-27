# Deploy Market Sniper Auth Gateway (Org Policy Bypass)
# Run this if Agent is blocked by GCloud Auth.

$PROJECT_ID = "marketsniper-intel-osr-9953"
$REGION = "us-central1"
$SA_EMAIL = "ms-api-gateway-invoker@marketsniper-intel-osr-9953.iam.gserviceaccount.com"

Write-Host "1. Creating API Resource..."
gcloud api-gateway apis create ms-gateway-api --project=$PROJECT_ID

Write-Host "2. Creating API Config..."
gcloud api-gateway api-configs create ms-config-v1 --api=ms-gateway-api --openapi-spec=openapi.yaml --project=$PROJECT_ID --backend-auth-service-account=$SA_EMAIL

Write-Host "3. Creating Gateway..."
gcloud api-gateway gateways create ms-gateway --api=ms-gateway-api --api-config=ms-config-v1 --location=$REGION --project=$PROJECT_ID

Write-Host "4. Creating Founder API Key..."
gcloud beta services api-keys create --display-name="Market Sniper Founder Key" --project=$PROJECT_ID

Write-Host "DONE. Please capture the Gateway URL and API Key String for AppConfig."
gcloud api-gateway gateways describe ms-gateway --location=$REGION --project=$PROJECT_ID --format="value(defaultHostname)"
gcloud beta services api-keys list --project=$PROJECT_ID --format="value(keyString)"
