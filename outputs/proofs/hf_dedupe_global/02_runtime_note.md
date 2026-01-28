--- VERIFYING HF-DEDUPE-GLOBAL ---
[SETUP] Cleared caches for TEST_GLOBAL

[STEP 1] Run 1: Should be Global Miss & Compute
Run 1 Duration: 0.0185s
[PASS] Global Cache file created with public=True.
[SETUP] Cleared Local Cache to force Global Hit

[STEP 2] Run 2: Should be Global Hit
Run 2 Duration: 0.0015s
[PASS] Global Cache Hit verified. Source + Timestamp correct.

[STEP 3] Run 3: Should be Local Hit (Read-Through verified)
Run 3 Duration: 0.0020s
[PASS] Read-Through verified.

--- HF-DEDUPE-GLOBAL VERIFIED ---
