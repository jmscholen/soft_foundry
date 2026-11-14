# Test Plan

## Unit
ProcessRules: applies? on a record with and without `rules`; remediation_rounds from commits only, from phase_reopenings only, and both (takes the larger); round_allowed? at 1, 2 and 3 rounds with no decision, accept_residual, narrow and reject; must_cap per risk and an unknown risk; documentation_path? for README.md, docs/x.md, changes/<slug>/x, lib/x.rb, .ai/x.yml, a nested x.md outside docs; malformed workflow keys fail closed. Each new gate check on a planted record: pass, fail with the named field, and skip on a legacy record.

## Integration
CLI on fixture repositories (real git, scratch directories): `phase reopen remediate` at the cap (exit code, unchanged handoffs, status, printed decisions); with a decision; `phase seal remediate` past the allowance; `phase run remediate` auto-reopen refused (stub launcher); `phase seal specify` without and with approval; `change release` with person_checks; `phase reopen remediate --docs-only` and the seal refusal; `change size` on a documentation-only diff; the readme-workflow-visuals history replayed as commit messages to check the round count reads 8. Harness-eval gate cases for each new check through `soft-foundry eval`.

## Acceptance criteria coverage
| Criterion | Test layer | Planned test |
| --- | --- | --- |
| AC-001 (must) | integration | new record carries rules: 2; gate on a copy of readme-workflow-visuals' record reports legacy skips, outcomes unchanged |
| AC-002 (must) | integration | reopen at two rounds: exit non-zero, handoffs unchanged, awaiting_human, three decisions printed |
| AC-003 (should) | integration | phase run remediate with stale evidence at the cap: no session started |
| AC-004 (must) | unit + integration | review and judge gates at three rounds without and with a decision; reopen permitted once after the decision |
| AC-005 (must) | unit | specify gate: missing tier, tier "maybe" |
| AC-006 (must) | unit | specify gate: low risk, four and three must criteria |
| AC-007 (must) | integration | seal specify with no entry, partial entry, exact entry |
| AC-008 (must) | unit | judgment criteria check: uncovered should warns; uncovered must fails |
| AC-009 (must) | integration | person_checks not counted; change release carries them |
| AC-010 (must) | unit | blocked basis: empty, should id, outside_change finding, unmet must |
| AC-011 (should) | unit + integration | outside_change without follow_up fails; with follow_up shows in change status |
| AC-012 (should) | unit | default waivers at low risk; run_phases keeps attack; legacy unchanged |
| AC-013 (should) | integration | change size on docs-only diff, then with a lib/ path |
| AC-014 (should) | integration | docs-only reopen resets the named phases only and records docs_only |
| AC-015 (must) | integration | docs-only seal refused after a lib/ commit; allowed with README.md only |
| AC-016 (should) | inspection | skill text against REQ-013, read at verification |
| AC-017 (must) | integration | CHECKS entries, `soft-foundry eval` cases passing, documentation lines, compared by a script at verification |
| AC-018 (must) | full suite + ci | `rake test` and `soft-foundry ci` with keys and SOFT_FOUNDRY_PHASE unset |
| AC-019 (should) | unit | each new message with NO_COLOR and non-ASCII stripped keeps word, prefix and next action |

## Not covered and why
PC-001 is a person check, carried as a release item. TM-001's shell-written decision is residual: the test shows the seal note names the hand-edited key, not that the write is prevented.
