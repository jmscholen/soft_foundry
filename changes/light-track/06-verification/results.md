# Verification Results

Commit SHA: 4988779139bf6c8d60fdb9b985a55254b0659d1a (tree 68e021fc2b4b01b05cf610e4a34447a448c9aeaf)

`soft-foundry change size --phase verify` reported `full_at_verify` (no scope declared), so the full suite was run on this commit.

## Deterministic checks

| Check | What ran | Result |
| --- | --- | --- |
| CHECK-001 | Full suite, `bundle exec rake test`, provider keys and SOFT_FOUNDRY_PHASE unset | pass: 951 runs, 6990 assertions, 0 failures, 0 errors, 0 skips |
| CHECK-002 | `test/light_track_test.rb`, the change's own tests (RED commit a53ec00) | pass: 16 runs, 0 failures |
| CHECK-003 | `test/lifecycle_tracks_test.rb` | pass: 25 runs, 0 failures |
| CHECK-004 | `soft-foundry check` | pass |
| CHECK-005 | `soft-foundry ci` (check, harness evals, gate of every open record) | pass: 35 evals passed, 0 failed, 1 skipped by the tool; exit 0 |
| CHECK-006 | `ruby -wc` on the eight changed Ruby files | pass: no syntax error, no warning |
| CHECK-007 | CLI probe against a throwaway repository | pass |
| CHECK-008 | Path normalization probe | pass |
| CHECK-009 | Existing tests and harness evals unchanged | fail: one existing assertion changed |
| CHECK-010 | Skill wording for AC-006 | pass |
| CHECK-011 | Light track documented in help and workflow.yml for AC-007 | fail: help text incomplete |

All commands ran the worktree's code (`ruby -Ilib exe/soft-foundry`), not the installed gem.

## Criteria

| Criterion | Tier | Covered by | State |
| --- | --- | --- | --- |
| AC-001 | must | CHECK-002 | pass |
| AC-002 | must | CHECK-002 | pass (the third state is tested as implementation DEV-001 describes: reopen refused at two rounds, gate check fails at three) |
| AC-003 | must | CHECK-002, CHECK-008 | pass |
| AC-004 | should | CHECK-002 | pass |
| AC-005 | should | CHECK-002, CHECK-007 | pass |
| AC-006 | should | CHECK-010 | pass |
| AC-007 | should | CHECK-011 | fail in part (VER-002) |
| AC-008 | should | CHECK-002, CHECK-007 | pass |
| AC-009 | should | CHECK-001, CHECK-003, CHECK-005, CHECK-007, CHECK-009 | fail in part (VER-001) |

## Failures

- CHECK-009 (AC-009, should). `test/lifecycle_tracks_test.rb` line 51 changed from `%w[gated iterative]` to `%w[gated iterative light]`. AC-009 says no existing assertion is changed. Implementation recorded this as DEV-003. Every other existing test passes unchanged, and no harness-eval file changed. Not repaired here.
- CHECK-011 (AC-007, should). `soft-foundry help` shows the light track only in `--track gated|iterative|light`. AC-007 asks that the help name the track's required phases, the locks it keeps and the high-risk exclusion. `.ai/workflow.yml` does name them. README.md and `docs/user/` are not in this skill's read set, so their part of AC-007 is not evidenced by this phase. Not repaired here.

## Observations that are not failures

- No test drives `soft-foundry phase seal` on a light-track record (REQ-002, "phase seal advances past it"). The tests cover the gate's predecessor check, `reached_lifecycle_end?` and `change close`; the seal uses the same `skippable?` rule (VER-003).
- `normalize_path` returns `lib\app.rb` and `LIB/app.rb` unchanged, so on a case-insensitive file system a finding spelled `LIB/app.rb` would not match the modified `lib/app.rb`. AC-003 does not list these spellings (VER-004).
- The gem installed on this machine (reports 0.23.0) fails `predecessor complete` on this record (`04-plan is pending`); the worktree's code passes it. The runner uses the worktree's code (VER-005).

## Evidence

Listed with SHA-256 in `evidence/manifest.yml`. No payload contains hidden characters; none is shown escaped.

Evidence generated for a different implementation commit is stale.
