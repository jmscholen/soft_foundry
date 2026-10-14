# Functional Review

Commit reviewed: a9fac32d0c0e2d8951ee09ed0a5c9a8102c34637 (application code identical to ac3e8cf, the commit verification, evaluation and attack last described).

## Scope reviewed
REQ-FR-001 to REQ-FR-010 against `02-specification/`, the diff `6bf2127..HEAD` for `lib/` (gate.rb, change_record.rb, text.rb, hooks.rb, git.rb, guard.rb, harness_eval.rb, cli.rb) and `.ai/`, verification results (568 runs, 0 failures, default and C locale, `check` and `eval` clean), evaluation journeys EVAL-001 to EVAL-010, and remediation REM-001 to REM-006. I did not rerun the 8.5-minute suite; no application or test code changed after verification's commit, so its result describes this HEAD.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-004 | minor | `lib/soft_foundry/hooks.rb` GUARD_AFTER, host contract | The restore runs from a PostToolUse hook. Whether Claude Code fires PostToolUse for a Bash call that exits non-zero was not exercised by verification, evaluation or attack (attack lists real host payloads as not exercised). | If it does not fire, `cd x; printf ... > enforcement.yml; false` leaves the guard in warn until the next successful shell call's post hook; a Write in between is allowed with a warning. Unverified, hence minor. | REQ-FR-004 |
| REV-006 | minor | Rails profile in `.ai/repository.yml` / discovery | The Rails profile records testing as `ruby`, not an rspec-named entry (EVAL-F2). | A Rails repository whose tests are rspec is described to later phases as generic ruby tests; a rule keyed on rspec does not load. | REQ-FR-008 |
| REV-007 | minor | `README.md` live eval section | A default `eval --live --shell claude` invocation in a non-interactive session fails with "0 findings recorded" because the shell may not write the phase directory; README mentions only the `phase run --shell-arg` form (EVAL-F1). | A maintainer following the README reports the harness broken when the eval is a permission failure. | REQ-FR-005, AC-FR-015 |

Behaviour otherwise conforms: waivers by risk, judgment never waived at close, specification lock on the gated track, `read_text` for every record read, the application-repository journey, and the eval runner (12 pass, 0 fail, 1 skip) all match their criteria in verification and evaluation. The gate's `evidence current` check also fails correctly when the specification is re-recorded after the evidence.

## Conformance
Conforms with the minor findings above. Documentation gaps are REV-001 (architecture.md).
