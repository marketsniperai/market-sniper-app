# SEAL_D55_4_SSL_CERT_PROVISIONING_UNBLOCK

## Status
**CERTIFICATE STATUS:** GREEN (ACTIVE)
**ACCESS STATUS:** RED (403 Forbidden)

## Summary
The Google Managed Certificate `msr-api-cert` for `api.marketsniperai.com` is **ACTIVE**.
However, public access to the endpoint is blocked by a Cloud Run IAM restriction (`FAILED_PRECONDITION`), likely a specialized Organization Policy (`constraints/iam.allowedPolicyMemberDomains`) preventing `allUsers` from being granted `roles/run.invoker`.

## Diagnostics

### 1. Certificate State (Success)
- **Certificate Name**: `msr-api-cert`
- **Domains**: `api.marketsniperai.com`
- **Status**: `ACTIVE`
- **Attached Proxy**: `msr-https-proxy`

### 2. DNS State (Success)
- **A Record**: `34.36.210.87` (Matches Load Balancer IP)
- **AAAA Record**: None (Correct - avoids connectivity issues)
- **CAA Record**: Implicitly allowed / None blocking.

### 3. Access Block (Action Required)
- **Error**: `HTTP/1.1 403 Forbidden`
- **Cause**: Cloud Run Service `marketsniper-api` requires authentication.
- **Fix Attempt**: Tried adding `allUsers` -> `roles/run.invoker`.
- **Fail Reason**: `FAILED_PRECONDITION: One or more users named in the policy do not belong to a permitted customer, perhaps due to an organization policy.`
- **Remediation**: The Organization Administrator must disable the "Domain Restricted Sharing" constraint for this project or folder to allow public access to Cloud Run services.

## Evidence
- `outputs/proofs/d55_4_ssl/infra_snapshot.txt`: Confirms `managed.status: ACTIVE`.
- `outputs/proofs/d55_4_ssl/dns_checks.txt`: Confirms correct A records.
- `outputs/proofs/d55_4_ssl/final_verification.txt`: Captures 403 Forbidden response.
- `outputs/proofs/d55_4_ssl/iam_error.txt`: Captures the Organization Policy error.

## Cleanup
- Deleted `msr-cert` (FAILED_NOT_VISIBLE).

## Next Steps
- **IMMEDIATE**: Disable `constraints/iam.allowedPolicyMemberDomains` on the project `marketsniper-intel-osr-9953` to allow `allUsers` binding.
- **RETRY**: Re-run `gcloud run services add-iam-policy-binding ...` once policy is lifted.
