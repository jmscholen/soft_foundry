# Architecture Review

## Scope reviewed

The same commit and diff as the functional review, read against `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, and `.ai/rules/dependencies.md`. No database. No new gem. `soft_foundry.gemspec` already takes `SoftFoundry::VERSION`, so the 0.21.0 to 0.22.0 bump does not need a second edit.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | `lib/soft_foundry/cli.rb` single-run return versus `parallel_run` | See the functional review. The blocked-mark helper is shared. The decision to exit 2 lives only on the single-run return. The parallel return still uses session status and `result.failed?`, and a blocked handoff produces a gate warning, so `failed?` is false. | Same as REV-001 in `functional.md`. | `.ai/rules/architecture.md` (one owner for a cross-cutting outcome); `.ai/rules/general.md` |

No further architecture finding.

## Conformance

Conforms, with REV-001.

`ChangeSummary` is a reader over metadata and handoffs. Keeping it out of `Snapshot` matches the recorded decision: the summary must not run the gate, and `Snapshot` is built around the gate and the JSON board. `Display` is the one escaper for the new lines that echo recorded text. `ChangeRecord::TYPES` and `RISKS` are the vocabulary `create`, the CLI usage line, and `check` share. `protection stated` sits with the other verification checks in `Gate` and is registered only for verify.

`mark_blocked!` takes the runner's phase argument, changes `status` and `notes` only, and uses `update_handoff`, so a parallel finish takes the record lock. `finish!` already rewrites the handoff through that same path, so the comment-stripping YAML dump is the existing writer, not a new one.

`advisory_lines` rescues `StandardError`, prints a `note:` line, and still returns the other facts. That is the summary's specified failure behavior (one bad read does not hide the rest), with the exception class and the recovery stated in the method.

The implementation decision to put the summary in its own file, to exit 2 on a single blocked run, and to treat `not_applicable` like `disabled` when nothing is `in_force` is recorded in `05-implementation/decisions.md` and matches the code. The parallel half of that exit decision does not match the code path that was supposed to already fail the process (REV-001).
