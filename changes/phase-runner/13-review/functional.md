# Functional Review

## Scope reviewed
Every requirement in `00-intake/request.md` (REQ-RUN-001 to REQ-RUN-010) against commit `9f855b51`: `lib/soft_foundry/phase_runner.rb`, the `phase run` command and `spawn_shell` in `cli.rb`, `Shell.resolve`, `Advisory#fresh_context_notices`, the gate's branch-aware `staleness_check` with `Git#changed_between` and `branch_tip`, the hook ordering, the templates and documentation, the three test files, and the evaluation transcript.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | minor | `lib/soft_foundry/phase_runner.rb` `SHELLS` | The `claude -p` and `codex exec` invocations are assumed, not verified against a real session in this change (the evaluation used fake shells). A real run is the natural next step and should be the first thing the next change does with `phase run review`. | REQ-RUN-001 |
| REV-002 | minor | `lib/soft_foundry/cli.rb` `phase` | A session that exits 0 without writing the handoff leaves `status: in_progress` with `executed_by` complete and the gate saying "not yet gated"; the runner exits 0 because the gate does not fail on `in_progress`. A stricter runner would exit non-zero when the phase is not `complete` after a successful session. Follow-up: an `--expect-complete` default. | REQ-RUN-004 |
| REV-003 | info | `lib/soft_foundry/phase_runner.rb` `begin!` | `current_phase` is moved before launch and not moved back after; the runner leaves the record pointing at the last phase run, which is what `AGENTS.md` step 4 expects the next reader to find. `previous_phase` is kept in `executed_by` for the trail. | REQ-RUN-003 |
| REV-004 | info | `lib/soft_foundry/gate.rb` `staleness_check` | On a detached CI checkout the current branch is `HEAD`, so every record is measured against its own branch's `origin/` tip. For the PR's own record that tip is the PR head, so a PR that pushed after generating evidence still reads stale, as it should; uncommitted edits cannot exist in CI. | REQ-RUN-008 |
| REV-005 | info | `lib/soft_foundry/advisory.rb` `fresh_context_notices` | Reads only `executed_by.fresh_context == true`; an agent could write that field by hand. Same trust level as `vetted` and `human_decisions`, stated in `security.md`. | REQ-RUN-007 |

## Conformance
Conforms. Every requirement is implemented and exercised: REQ-RUN-001 by the dry-run and run tests and EVAL-001/003; REQ-RUN-002 by the refusal test and EVAL-002; REQ-RUN-003 and 004 by the run, failed-session, and failing-gate tests and EVAL-003/004; REQ-RUN-005 and 006 by the dry-run tests and EVAL-001; REQ-RUN-007 by the advisory and template tests, three adjusted accessibility tests, and EVAL-005; REQ-RUN-008 by the five stacked-branch tests and `ci` on this very branch; REQ-RUN-009 by the hook text, the committed settings file, the profile and maturity edits, and the documentation; REQ-RUN-010 by the 281 unchanged prior tests.
