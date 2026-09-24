# Functional Review

## Scope reviewed
Every requirement in `00-intake/request.md` (REQ-GRD-001 to REQ-GRD-010) against commit `e5c48dcf`: `lib/soft_foundry/guard.rb`, the `guard`, `hooks`, and `doctor` code in `cli.rb`, `hooks.rb`, `check.rb`'s `check_enforcement`, the policy file, the documentation, `test/guard_test.rb`, and the evaluation transcript.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | minor | `lib/soft_foundry/guard.rb` `shell_paths` | The Bash heuristic splits on whitespace and shell metacharacters, so a path with a space inside quotes (`"my dir/file"`) is split and missed, and a path built by variable expansion (`$DIR/policies`) is invisible. Deny-only by design, so a miss is a pass-through, never a false refusal; documented in the policy file. Follow-up: quote-aware tokenising. | REQ-GRD-001 |
| REV-002 | minor | `lib/soft_foundry/guard.rb` `active` | The record is read on every tool call (three YAML files). Fast enough for a hook today (tens of milliseconds), but a repository with a very large `metadata.yml` would feel it on every edit. No caching, by choice: the record is the source of truth and can change between calls. | REQ-GRD-002 |
| REV-003 | info | `lib/soft_foundry/cli.rb` `guard` | The mode is read before the payload, so `off` never touches stdin or the record. A hook in off mode costs one file read. | REQ-GRD-003 |
| REV-004 | info | `lib/soft_foundry/hooks.rb` `GUARD_COMMAND` | The command embeds the marker as a shell comment on its first line, so the marker survives Claude Code's schema (no extra keys) and is visible to anyone reading the settings file. The fallback to `ruby -Ilib exe/soft-foundry` only works when the shell's cwd is a Soft Foundry checkout, which is the same limitation the pre-commit hook has. | REQ-GRD-005 |
| REV-005 | info | `lib/soft_foundry/guard.rb` `decide` | NotebookEdit reads `notebook_path`; MultiEdit reads `file_path`; both are the documented field names. A future tool with a different field is allowed silently ("no file path in the tool call") rather than refused, which is the correct default for a hook whose matcher may be widened later. | REQ-GRD-001 |

## Conformance
Conforms. Every requirement is implemented and exercised: REQ-GRD-001 by the decision-matrix tests and EVAL-003 to EVAL-005; REQ-GRD-002 by the no-record, closed, phase, and exploring tests and EVAL-002/006/008; REQ-GRD-003 by the mode tests and EVAL-003/004/007; REQ-GRD-004 by the fail-closed test and EVAL-007; REQ-GRD-005 by the install tests and EVAL-001; REQ-GRD-006 by the doctor test and EVAL-001/010; REQ-GRD-007 by the `check` test and EVAL-009; REQ-GRD-008 by the shipped policy and the documentation edits; REQ-GRD-009 by the profile and maturity edits; REQ-GRD-010 by the 265 unchanged prior tests and `ci` against this repository.
