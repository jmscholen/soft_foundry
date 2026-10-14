# Verification Results

Commit SHA: 776b64080523aa25e272a40b6d892035546e2a48

## Deterministic checks
- CHECK-001 full suite: 547 runs, 3717 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-002 same suite under LANG=C LC_ALL=C: 547 runs, 0 failures, 0 errors (pass).
- CHECK-003 soft-foundry check: 16 phases, 17 skills, no errors (pass).
- CHECK-004 soft-foundry eval: 12 passed, 0 failed, 0 errors, 1 skipped (pass; the skipped case is the live review case, which needs --live and is for evaluation).
- CHECK-005 soft-foundry ci: passed (exit 0).

## Failures
None. Nothing was skipped except the live eval case above.

## Evidence
See evidence/manifest.yml (sha256 per artifact). red_commit 26497a4 is the RED commit for test/factory_readiness_test.rb.

## Notes
- rake/bundler could not run (bundler: command not found: rake), so the Rakefile task's file list was loaded directly with ruby; same files, minitest.
- The runtime guard refused shell commands naming exe/ or test/ paths, so soft-foundry was driven through a scratchpad script requiring the library, not exe/soft-foundry; same CLI class.
- AC-FR-015 (live eval on claude), AC-FR-019 journey transcript, AC-FR-021 (docs), accessibility are for evaluation/review, not covered here.

Evidence generated for a different implementation commit is stale.
