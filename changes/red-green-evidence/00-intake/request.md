# Change Intake

## User intent
Third of the five additions from the ECC evaluation, agreed with "ok, lets do the 5 recommended additions": RED and GREEN checkpoint commits as commit-bound evidence. ECC's TDD skill requires one commit in which the failing test exists and one in which the implementation makes it pass. Soft Foundry's verification phase binds evidence to a commit but has no shape for "the test failed first"; `.ai/rules/testing.md` asked for tests that verify behaviour and regression tests for fixes, but never for the test to precede the code. The repository profile has recorded `evidence.failed_results_retained: PARTIAL` (policy only) since discovery.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-RG-001.** A check in `06-verification/tests.yml` may carry `red_commit` (the commit at which its test existed and failed) and `test_path`. The template documents both as optional.
- **REQ-RG-002.** The verification gate carries a `red evidence` check. For each check naming a `red_commit` it fails when the value is not a commit in the repository, when it is the verified commit itself, when it is not an ancestor of the verified commit, when `test_path` (if given) does not exist at the RED commit, or when no `APP` or `INFRA` path changed between the RED commit and the verified commit. It passes naming each check's RED and GREEN commits and test file. It is skipped when no check names a `red_commit` or `tests.yml` is missing, and fails when `tests.yml` is not valid YAML.
- **REQ-RG-003.** The check does not re-run the test at the RED commit; the claim that it failed there is the agent's, bound to a commit anyone can check out. The documentation says so.
- **REQ-RG-004.** A change of type `feature`, `fix`, or `refactor` whose verification is complete with no check naming a `red_commit` draws a `! warn verification:` advisory on every gate, status, ci, and close run; other types and pending verifications do not. The advisory never changes an exit code.
- **REQ-RG-005.** `.ai/rules/testing.md` asks for the failing test to be committed before the implementation; the implementation skill says to do so and name the commits; the verification skill says to record the RED commit as `red_commit` only when confirmed. `README.md` and `.ai/schemas.md` document the fields, the check, and the advisory.
- **REQ-RG-006.** This repository's profile keeps `evidence.failed_results_retained: PARTIAL` with an updated finding (the RED commit is enforced; other failed results remain policy), `.ai/maturity.yml` says what PASS would take, and the version is 0.12.0.
- **REQ-RG-007.** This change is itself done test-first: its tests are committed before its implementation, and its own verification record names that commit as `red_commit`.

## Constraints
- The gate asks git read-only questions and writes nothing.
- Checks without `red_commit` keep passing exactly as before; the field is optional and every existing record is unaffected at the gate (the advisory is new and reports on open feature records, by design).
- Every new line carries its outcome as a word per `.ai/rules/accessibility.md`.

## Non-goals
- Re-running tests at the RED commit. A check-out-and-run harness would prove the failure; this change binds the claim, it does not reproduce it.
- Requiring `red_commit`. It is advised for features, fixes, and refactors, never required; a docs or chore change has nothing to fail first.
- Detecting a test that was made to fail trivially. Content is the review's job.

## Task classification
Feature: a gate check, an advisory, two git primitives, template and rule text, documentation, a profile finding, tests, and the change's own RED commit.

## Initial risk
low. Read-only questions to git inside the gate; optional fields; an advisory. Existing tests and change records pass unchanged at the gate.
