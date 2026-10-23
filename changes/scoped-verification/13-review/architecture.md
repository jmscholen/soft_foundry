# Architecture Review

## Scope reviewed

`.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, `.ai/rules/learned.md` (`measure-staleness-on-the-record-branch`), and the module split in `04-plan/implementation.md`. Compared with `scope.rb`, `sizing.rb`, `full_suite.rb`, `declarations.rb`, `gate.rb`, `advisory.rb`, `cli.rb`, and `git.rb` at `8575131`.

One classifier (`Scope`) still owns staleness, sizing, and the advisories. Consumers read the gate result and do not reimplement the path rules. `Git#diff_paths` lists both sides of a rename. Declaration values are compared only when the file appears in the diff. Those choices match the implementation decisions and the architecture rules.

The measure rule does not. `Scope.tip_for` returns the recorded branch tip when the branch is checked out (it returns nil and HEAD is used), when the tip equals or descends from HEAD, or when the tip strictly descends from the evidence commit. The third clause is what ATTACK-019 and ATTACK-020 use, and it is the same shape as the stacked branch ATTACK-021 keeps. `Gate#staleness_check`'s comment still describes the older rule ("when that branch exists and is not the one checked out") rather than this predicate. `Sizing`'s class comment still says the smaller verify size applies only when every changed code path is inside the record's scope; `verify` treats a path claimed by another record as the smaller size, which is what `.ai/policies/check-sizing.yml` now says. Neither comment produces a wrong result on its own.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | blocking | `lib/soft_foundry/scope.rb` `tip_for` | The branch-tip rule from `.ai/rules/learned.md` is implemented with an ancestry predicate that also accepts a ref created after the evidence commit. Stacked measurement and the laundered branch are the same commit graph, so the classifier cannot tell them apart. | Record `git.branch: frozen` before `frozen` exists, create `frozen` at the phases-complete commit, then commit code on the checked-out branch. The classifier reports no code change on `frozen`, and `gate verify` exits 0 (`transcript3.txt`, ATTACK-019; `transcript4.txt`, ATTACK-020). | `.ai/rules/learned.md` `measure-staleness-on-the-record-branch`. `.ai/rules/general.md` (do not convert a failed comparison into success). |
| REV-006 | minor | `lib/soft_foundry/scope.rb` `tip_for` | The same predicate refuses a recorded branch whose tip equals the evidence commit, so the stacked measure the learned rule requires does not apply to that tip. | `commit_sha` equal to the tip of the record branch, then a commit on a branch cut from that tip. `evidence current` fails. One later commit on the record branch, as in `test/stacked_branch_test.rb`, stays current. | `.ai/rules/learned.md` `measure-staleness-on-the-record-branch`. |

## Conformance

Does not conform. The module split conforms. The measure rule in `tip_for` does not: it hides later code in the ATTACK-019 shape and drops the stacked measure when the branch tip equals the evidence commit.
