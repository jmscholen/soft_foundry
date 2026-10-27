# Verification Results

Commit SHA: cf932d1f40b7dfad1abaac9be3b72005c15966b6 (tree 05de602d463c1605cec05972bfb28c1370fbf4c1)

## Deterministic checks
- `soft-foundry change size --phase verify`: full_at_verify (no scope declared in metadata.yml, so whole repository).
- CHECK-001 full suite, provider keys and SOFT_FOUNDRY_PHASE unset: 821 runs, 6222 assertions, 0 failures, 0 errors, 0 skips. Passed.
- CHECK-002 `soft-foundry check`: pass (16 phases, 17 skills, no errors).
- RED commit e496c67 holds the new tests (test/protection_stated_test.rb among them); GREEN 42b1689 changed lib/ afterwards.
- Protection: the repository profile lists no access_control paths, so protection is not_applicable on every check.

## Failures
- CHECK-003: the first full run inherited SOFT_FOUNDRY_PHASE=verify from the phase runner and produced 12 failures and 1 error (ReleaseStateTest, ApplicationRepoTest, CrossCliHooksTest, GuardTest, GuardIndirectionTest). The guard and discharge code read that variable, so the tests see a live phase session. This is environmental: the same tree passes with the variable unset (CHECK-001). The failing output is preserved and no test or code was changed. The suite does not isolate itself from an inherited SOFT_FOUNDRY_PHASE; reported as a finding.
- An earlier attempt was stopped at the 10-minute background limit and rerun with a longer limit.

## Evidence
evidence/full-suite.txt, evidence/check.txt, evidence/full-suite-with-phase-env.txt (hashes in evidence/manifest.yml).
Not run: any live phase-run exercise of the new features beyond the test suite.
Note: HEAD cf932d1 differs from the implementation commit 42b1689 only by control-plane and README text; the full suite ran on cf932d1.

Evidence generated for a different implementation commit is stale.
