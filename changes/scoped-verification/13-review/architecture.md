# Architecture Review

## Scope reviewed

`.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, `.ai/rules/learned.md` (including `measure-staleness-on-the-record-branch`), and the module split in the plan. Compared with `scope.rb`, `sizing.rb`, `full_suite.rb`, `declarations.rb`, `gate.rb`, `advisory.rb`, `phase_runner.rb`, `snapshot.rb`, and `cli.rb` at `85edc8e`.

`Scope` is the classification used by staleness, sizing, and the advisories. `phase_runner.rb`, `snapshot.rb`, `cli.rb` status, and the browser snapshot read `Gate#stale?` and carry no second staleness predicate (`test_consumers_hold_no_staleness_logic_of_their_own`). `Sizing` and `FullSuite` are separate modules with small public APIs, which is a justified split from the plan's single result object: the gate calls them, and they do not reimplement path classification. Git commands use argument arrays, `--`, and a hash check before any ref is interpolated. New YAML for declarations and the sizing policy loads with aliases disabled. No new gem dependency.

The learned rule that an earlier record is measured on its own branch is implemented by `Scope.tip_for`. REV-001 is that rule with no distinction between a branch that existed when the evidence was recorded and a branch created later at that commit. `branch_edit` compares the text of `git.branch`, so a value that does not change is invisible.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | blocking | `Scope.tip_for` / `Scope.branch_edit` | The branch measure has a single input, the current `git.branch` string, and treats "branch now exists and contains the evidence commit" as the stacked-branch case. | Same input as in the functional review: a pre-recorded branch name, the branch created at the evidence commit, later code on the checked-out branch. Evidence stays current. | `.ai/rules/learned.md` `measure-staleness-on-the-record-branch`; `.ai/rules/general.md` (a fallback must not turn an integrity failure into success, shared with `.ai/rules/errors.md`). |
| REV-002 | major | `Sizing#verify` | Sizing drops `claimed by another record` entries before deciding the size, so the size is not the same decision as "is this path inside the declared scope" that the policy file describes. Advisory still lists those paths as outside the scope. | Same input as in the functional review. Two readers of one `Scope::Result` disagree: the advisory says the path is outside, the size command says the smaller size. | `.ai/rules/architecture.md` (one owner for a cross-cutting decision); plan step 6. |

## Conformance

Conforms with findings REV-001 and REV-002. The layering matches the repository: one classifier, gate-owned staleness, consumers that only read it. The two findings are places that classifier's result is applied more loosely than the policy text.
