# Architecture Review

## Scope reviewed

The same commit and diff as the functional review, read against `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, and `.ai/rules/dependencies.md`. No database. No new gem. `soft_foundry.gemspec` already takes `SoftFoundry::VERSION`, so the 0.21.0 to 0.22.0 bump does not need a second edit.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-010 | minor | `lib/soft_foundry/cli.rb` `parallel_run` | See the functional review. The process status and the per-phase tally are both decided in this method, and they disagree when the session wrote `blocked` itself. The runner-marked case now uses one rule on the single-run return and the parallel return: exit 2. | Same as REV-010 in `functional.md`. | `.ai/rules/architecture.md` (one owner for a cross-cutting outcome); `.ai/rules/general.md` |

No further architecture finding. REV-002, REV-003, REV-006, and REV-011 are behavioral and are recorded in the functional review.

## Conformance

Conforms, with REV-010.

`ChangeSummary` is a reader over metadata and handoffs. Keeping it out of `Snapshot` matches the recorded decision: the summary must not run the gate, and `Snapshot` is built around the gate and the JSON board. `Advisory#notices` reads the record and git; it does not construct `Gate`. `Display` is the one escaper for the new lines that echo recorded text. `ChangeRecord::TYPES` and `RISKS` are the vocabulary `create`, the CLI usage line, and `check` share. `protection stated` sits with the other verification checks in `Gate` and is registered only for verify.

`mark_blocked!` takes the runner's phase argument, changes `status` and `notes` only, and uses `update_handoff`, which re-reads under the record lock. `finish!` already rewrites the handoff through that same path, so the comment-stripping YAML dump is the existing writer, not a new one. The rescue in `mark_blocked` reports the exception, returns false, and leaves the handoff for the gate.

The implementation decision to put the summary in its own file, to exit 2 when the runner marks a phase blocked, and to treat `not_applicable` like `disabled` when nothing is `in_force` is recorded in `05-implementation/decisions.md` and matches the code on both the single-run return and the parallel return. The parallel tally still prints `fail` for a blocked phase status that the exit treats as a warning (REV-010).
