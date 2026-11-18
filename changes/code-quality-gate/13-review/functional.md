# Functional Review

## Scope reviewed
This is the second review, after remediation round 1. It covers the whole diff from `f508df2` (specification sealed) to `1650d93` (HEAD; the code is the GREEN commit `b118833`, recorded at `459fa86`). I read it against REQ-001 to REQ-014 and AC-001 to AC-012 in `02-specification/`. Since the first review (`818165e`), the only code changes are in `lib/soft_foundry/maturity_scan.rb` (`quality_gate`, new `set_by_a_person?`), the comment in `.ai/templates/repository.yml`, and two tests in `test/code_quality_gate_test.rb`. Everything else I read in the first review (`change_record.rb`, `gate.rb`, `control_plane.rb`, `process_rules.rb`, `snapshot.rb`, `.ai/workflow.yml`) is byte-identical at HEAD, so those conclusions still hold.

Run by this session with provider keys and `SOFT_FOUNDRY_PHASE` unset:
- `ruby -Ilib -Itest test/code_quality_gate_test.rb`: 29 runs, 223 assertions, 0 failures.
- `test/maturity_scan_test.rb`: 11 runs, 0 failures.
- Scratch git repositories, each holding a `Gemfile` and one `.rb` file, using the worktree's `exe/soft-foundry`:
  - `init --root <dir> --maturity scan` gives `{enabled: true, set_by: "soft-foundry (language scan: ruby)"}`.
  - With `set_by: "  "` (whitespace only) and `enabled: false`, `onboard --reassess` replaces it with `enabled: true`. This is the case VER-004 said no test covers.
  - With `set_by: Someone` and `enabled: false`, `onboard --reassess` keeps the person's value.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | resolved (was blocking) | `lib/soft_foundry/maturity_scan.rb:88-99` | Fixed at `b118833`. `set_by_a_person?` treats a blank `set_by` as unset, so the template's `set_by: null` no longer blocks the scan. A new test runs `init --maturity scan` on a Ruby fixture, and my scratch run above confirms it. | — | REQ-004, AC-012 |
| REV-002 | minor | `test/code_quality_gate_test.rb` (AC-008) | Still open. AC-008 is covered only by structure (VER-001): the shared `cap_check` is asserted on the quality gate, but no test drives a third round. | None found: the same check runs for review and judgment and is tested there. | AC-008 (should) |
| REV-003 | minor | `test/process_speed_test.rb` | Still open, and justified. The rules-number assertion moved from 2 to 3 because REQ-004 requires it (DEV-004). | None. | REQ-012 |

## Conformance
Conforms. With REV-001 fixed, onboarding turns the gate on in a newly initialized Ruby repository, as REQ-004, AC-012 and `docs/user/code-quality-review.md` (lines 18-19) state. The rest of the specification is met, as found in the first review.
