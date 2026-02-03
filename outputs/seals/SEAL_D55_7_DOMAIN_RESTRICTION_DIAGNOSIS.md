# SEAL_D55_7_DOMAIN_RESTRICTION_DIAGNOSIS

## Status
**DIAGNOSIS:** COMPLETE
**BLOCKER CONFIRMED:** `constraints/iam.allowedPolicyMemberDomains`
**EFFECTIVE RESTRICTION:** `C03fwchpd` (marketsniperai.com)

## Summary
The inability to make Cloud Run services public (`allUsers`) is caused by the Organization Policy `iam.allowedPolicyMemberDomains`.
This policy is effectively enforced on the project `marketsniper-intel-osr-9953`, limiting all IAM valid members to the Customer ID `C03fwchpd`.
Since `allUsers` is not part of this customer domain, the IAM binding fails with `FAILED_PRECONDITION`.

## Evidence

### 1. Access Attempt Failure
**Command:** `gcloud run services add-iam-policy-binding ... --member="allUsers" ...`
**Error:**
```text
FAILED_PRECONDITION: One or more users named in the policy do not belong to a permitted customer, perhaps due to an organization policy.
```
**Proof:** `outputs/audit/d55_7/allUsers_attempt.txt`

### 2. Effective Policy
**Constraint:** `constraints/iam.allowedPolicyMemberDomains`
**Effective Configuration:**
```yaml
name: projects/553550349208/policies/iam.allowedPolicyMemberDomains
spec:
  rules:
  - values:
      allowedValues:
      - C03fwchpd
```
**Proof:** `outputs/audit/d55_7/allowedPolicyMemberDomains_effective.txt`

### 3. Organization Identity
Top-level Organization ID: `4018819876` (marketsniperai.com).

## Remediation Required
To allow public access (`allUsers`) to Cloud Run:
1.  **Action:** The Organization Administrator must **modify** the `iam.allowedPolicyMemberDomains` policy on the **Project** `marketsniper-intel-osr-9953`.
2.  **Change:** Set the policy to **Allow All** (or remove the rule enforcing specific domains) for this project.
3.  **Alternative:** If public access is strictly forbidden by policy, `marketsniper-api` CANNOT be made public. You must rely on the Load Balancer (D55.3) or authenticated proxies.

## Hygiene
```text
```
MM PROJECT_STATE.md
MM backend/api_server.py
 M backend/os_ops/autofix_control_plane.py
 M backend/os_ops/elite_os_reader.py
 M backend/os_ops/war_room.py
MM docs/canon/OMSR_WAR_CALENDAR__35_45_DAYS.md
 M market_sniper_app/lib/config/app_config.dart
M  market_sniper_app/lib/main.dart
M  market_sniper_app/lib/models/war_room_snapshot.dart
MM market_sniper_app/lib/repositories/war_room_repository.dart
M  market_sniper_app/lib/screens/war_room_screen.dart
 M market_sniper_app/lib/services/api_client.dart
AM market_sniper_app/lib/widgets/war_room/war_room_truth_metrics.dart
AM market_sniper_app/lib/widgets/war_room/zones/alpha_strip.dart
A  market_sniper_app/lib/widgets/war_room/zones/console_gates.dart
AM market_sniper_app/lib/widgets/war_room/zones/global_command_bar.dart
AM market_sniper_app/lib/widgets/war_room/zones/service_honeycomb.dart
M  market_sniper_app/lib/widgets/war_room_tile.dart
A  outputs/audit/d55_5_audit_logs.json
A  outputs/audit/d55_5_auditlog_summary.md
A  outputs/audit/d55_5_cloud_run.json
A  outputs/audit/d55_5_lb_backends.json
A  outputs/audit/d55_5_lb_certs.json
A  outputs/audit/d55_5_lb_forwarding_rules.json
A  outputs/audit/d55_5_lb_proxies.json
A  outputs/audit/d55_5_lb_url_maps.json
A  outputs/audit/d55_5_principal_scan.txt
A  outputs/audit/d55_5_resource_ownership.json
A  outputs/audit/d55_5_service_accounts.json
A  outputs/audit/d55_6_firebase_identities.txt
A  outputs/audit/d55_6_hosting_test.txt
A  outputs/audit/d55_6_identity_create.txt
A  outputs/audit/d55_6_invoker_grants.txt
A  outputs/audit/d55_6_project_iam.json
A  outputs/audit/d55_6_run_config.txt
A  outputs/audit/d55_6_run_iam.txt
A  outputs/audit/d55_6_sa_list.txt
A  outputs/audit/prod_openapi.json
A  outputs/audit/prod_routes.txt
A  outputs/proofs/d55_4_ssl/cert_poll_log.txt
A  outputs/proofs/d55_4_ssl/dns_checks.txt
A  outputs/proofs/d55_4_ssl/final_verification.txt
A  outputs/proofs/d55_4_ssl/iam_error.txt
A  outputs/proofs/d55_4_ssl/infra_snapshot.txt
A  outputs/seals/SEAL_D52_WAR_ROOM_DESIGN.md
A  outputs/seals/SEAL_D53_1_WAR_ROOM_COMPILE_FIX.md
A  outputs/seals/SEAL_D53_2_WAR_ROOM_EXIT_AND_SKELETON.md
A  outputs/seals/SEAL_D53_3A_ALPHA_STRIP_SLIVER_FIX.md
A  outputs/seals/SEAL_D53_3B_WAR_ROOM_EXIT_UNLOCK_PROOF.md
A  outputs/seals/SEAL_D53_3C_WAR_ROOM_PROOF_OF_LIFE.md
A  outputs/seals/SEAL_D53_3D_WAR_ROOM_REAL_PROOF_OF_LIFE.md
A  outputs/seals/SEAL_D53_3_WAR_ROOM_UNLOCK_EXIT_DENSITY_PASS.md
A  outputs/seals/SEAL_D53_4_WAR_ROOM_V2_POLISH.md
A  outputs/seals/SEAL_D53_5_WAR_ROOM_REAL_WIRING_PARTIAL.md
A  outputs/seals/SEAL_D53_6A_WAR_ROOM_TRUTH_PROOF_PANEL.md
A  outputs/seals/SEAL_D53_6Z_WAR_ROOM_VIEWPORT_NULL_FIX.md
A  outputs/seals/SEAL_D53_6_WAR_ROOM_TRUTH_EXPOSURE.md
AM outputs/seals/SEAL_D53_WAR_ROOM_STRUCTURAL_REFACTOR.md
A  outputs/seals/SEAL_D54_0A_WAR_ROOM_ENDPOINT_404_SLAYED.md
A  outputs/seals/SEAL_D54_0_WAR_ROOM_WEB_FETCH_AND_LAYOUT_HARDENING.md
A  outputs/seals/SEAL_D54_1_WAR_ROOM_ZERO_OVERFLOWS_POLISH.md
A  outputs/seals/SEAL_D55_4_SSL_CERT_PROVISIONING_UNBLOCK.md
AM outputs/seals/SEAL_D55_5_OWNERSHIP_AUDIT.md
AM outputs/seals/SEAL_D55_6_FIREBASE_HOSTING_REWRITE_UNBLOCK.md
 M requirements.txt
?? .firebase/
?? .firebaserc
?? .gcloudignore
?? artifacts/
?? bootstrap_firebase.ps1
?? bootstrap_firebase_v2.ps1
?? bootstrap_output.txt
?? bootstrap_v2_output.txt
?? cloudbuild_firebase.yaml
?? design/
?? discipline_check.log
?? firebase.exe
?? firebase.json
?? issues.txt
?? issues_final_v2.txt
?? issues_screen.txt
?? issues_zones.txt
?? market_sniper_app/errors.txt
?? market_sniper_app/issues_all.txt
?? market_sniper_app/lib/widgets/war_room/war_room_tile_meta.dart
?? market_sniper_app/openapi.json
?? market_sniper_app/tools/
?? outputs/audit/d55_7/
?? outputs/misfire_report.json
?? outputs/seals/SEAL_D53_6B_1_WAR_ROOM_NO_BLANK_GUARANTEE.md
?? outputs/seals/SEAL_D53_6B_2_WAR_ROOM_FLASH_BLANK_ROOT_CAUSE_FIX.md
?? outputs/seals/SEAL_D53_6B_WAR_ROOM_TILE_SOURCE_OVERLAY.md
?? outputs/seals/SEAL_D53_6C_WAR_ROOM_RESPONSIVE_DENSITY_LOCK.md
?? outputs/seals/SEAL_D53_6X_WAR_ROOM_WIDGET_DISAPPEAR_INVESTIGATION.md
?? outputs/seals/SEAL_D53_6Y_TRUTH_COVERAGE_METER.md
?? outputs/seals/SEAL_D54_2B_PY_DEV_PROXY_FOR_WEB.md
?? outputs/seals/SEAL_D54_3_CLOUD_RUN_REALITY_AUDIT.md
?? outputs/seals/SEAL_D55_0B_HEAD_OPTIONS_METHOD_HARDENING.md
?? outputs/seals/SEAL_D55_0D_PUBLIC_GATEWAY_PROXY_FOR_WEB.md
?? outputs/seals/SEAL_D55_0E_FIREBASE_HOSTING_REWRITE_WEB_UNBLOCK.md
?? outputs/seals/SEAL_D55_0_FULL_REDEPLOY_AND_ROUTE_RESTORATION.md
?? outputs/seals/SEAL_D55_1B_ZERO_HUMAN_FIREBASE_SA_AND_HOSTING_DEPLOY.md
?? outputs/seals/SEAL_D55_1_WEB_ACCESS_UNBLOCK_ZERO_HUMAN.md
?? outputs/seals/SEAL_D55_2_FIREBASE_HOSTING_BOOTSTRAP_FAILURE.md
?? outputs/seals/SEAL_D55_3_LB_WEB_UNBLOCK.md
?? outputs/seals/SEAL_D55_7_DOMAIN_RESTRICTION_DIAGNOSIS.md
?? task.md
?? tools/
