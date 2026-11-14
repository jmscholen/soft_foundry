# Architecture Review

## Scope reviewed

`lib/soft_foundry/process_rules.rb` and the callers the plan names: `PhaseReopen`, `PhaseSeal`, `Gate`, `Sizing`, `Release`, `ChangeRecord#skippable?`, `Advisory`, and `PhaseRunner`'s awaiting_human refusal. Compared with `.ai/rules/architecture.md` and `.ai/rules/general.md`. No new service boundary, database, or delivery mechanism. The gem remains a single process over a git worktree and the change record.

`ProcessRules` is the right seam. Callers do not reimplement tier lookup, the must cap, person checks, or the documentation-path test. Workflow keys fail closed through `TargetError`, and `check` lints them. Default waivers never include specify, review, or judgment. Legacy records skip the new checks with the reason "legacy record", which is what REQ-001 requires for records already in flight.

The enforcement points do not share one reading of whether the rules apply, or one history for the round count. That is REV-001 and REV-002.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | blocking | `PhaseSeal#remediation_refusal`, `PhaseReopen#refuse_over_cap!`, `Gate#cap_check` | Each of these reads `ProcessRules#applies?` from the current metadata. `rules kept` reads the intake seal and runs only on the first phase. Dropping `rules` makes the cap methods return before they refuse, while the intake gate is the only one that fails. | See REV-001 in `functional.md`. A third `phase seal remediate` succeeds after `rules` is deleted and committed. | `.ai/rules/architecture.md` (one owner for the cross-cutting control); `.ai/rules/general.md` (do not convert a failed invariant into success); MIT-007 |
| REV-002 | major | `ProcessRules#sealed_round_commits` | The plan says the count is commits reachable from the record's branch tip or HEAD. The code uses `branch_tip(git.branch)` and substitutes HEAD only when that name has no tip. Editable metadata chooses which history counts. The checked-out branch is enforced only at seal, so reopen and the review gate see the lowered count. | See REV-002 in `functional.md`. `git.branch: main` with the seals on the change branch permits the reopen and can pass the review cap check. | MIT-002; `.ai/rules/general.md` (invariants enforceable in one place) |
| REV-013 | minor | `lib/soft_foundry/git.rb` `count_subject` | When `git log` fails, the count is 0. Combined with no qualifying `phase_reopenings` entry, `remediation_rounds` is 0 and another round is allowed. A git failure is reported as no rounds. | `git log` for the record's branch returns not ok, `phase_reopenings` has no complete-remediate reset, and two `Record <slug> remediate` commits exist but cannot be read: the cap does not refuse the next remediation seal. | `.ai/rules/errors.md` (a fallback must not turn an integrity failure into apparent success); `.ai/rules/general.md` |

## Conformance

Does not conform. The module split matches the plan and the architecture rule against speculative layers. The cap is not one invariant: current metadata can switch it off at the methods that refuse a round (REV-001), and `git.branch` selects the history the count trusts (REV-002).
