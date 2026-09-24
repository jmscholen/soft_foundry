# Implementation Log

## Changes made
- `test/content_scan_test.rb` (new, committed first at `71d987f` as RED): eleven tests for the four kinds and their levels, the in-line marker, the policy allowlist and its validation, `check`, the gate, and `scan`.
- `lib/soft_foundry/content_scan.rb` (new): the pattern tables, `scan_text`, `scan_paths` with the allowlist, `allowlist`, `allowed?`, `allowlist_problems`, path helpers for the control plane, a record, and a phase; a null-byte probe for binary files.
- `lib/soft_foundry/check.rb`: `check_content` (allowlist problems plus the scan over `.ai/**`, `AGENTS.md`, `CLAUDE.md`).
- `lib/soft_foundry/gate.rb`: `content_check` on every complete phase.
- `lib/soft_foundry/cli.rb`: `scan [paths...]` with status-worded lines and a summary; help text.
- `.ai/policies/content-scan.yml` (new): the canary exemption for `init-command`'s closed evaluation evidence, with its reason. `.ai/rules/security.md`: one rule line. `README.md` ("Scanning the control plane as an attack surface"), `.ai/README.md`, `.ai/schemas.md`.
- `.ai/rules/learned.md`: the four instincts at or above 0.80 from learning-instincts, promoted through this record with `soft-foundry learn promote` (the first promotion).
- `test/learning_instincts_test.rb`: the fixture resets `learned.md` to the header, since the real file now accumulates.
- Version bumped to 0.14.0.

## Decisions
See `decisions.md`.

## Deviations from plan
None. See `deviations.md`.

## Lessons
- The first scan over this repository found something real on its first run: a canary key in closed evidence, placed there deliberately by an earlier evaluation. The right response was a reasoned exemption in policy, not an edit to closed evidence and not a weaker pattern.
- The scan then found this change's own evidence: the journeys wrote a zero-width character and a canary into the transcript on purpose. The harness now renders invisible characters as code points and masks key shapes before output becomes evidence; the evidence still says what happened, in words a scan does not mistake for an attack. Recorded as an instinct.
- Promoting instincts through this record broke the learning tests, because the fixture copies the real `.ai/` and the real `learned.md` now holds promotions. A ledger that grows is the feature; tests must reset what they assume empty.

## Challenges
None substantive.
