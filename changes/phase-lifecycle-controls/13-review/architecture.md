# Architecture Review

## Scope reviewed

Loaded the implementation baseline and the discovered language and testing rules: `.ai/rules/general.md`, `.ai/rules/architecture.md`, `.ai/rules/ruby.md`, `.ai/rules/errors.md`, `.ai/rules/dependencies.md`, `.ai/rules/git.md`, `.ai/rules/learned.md`, and `.ai/rules/testing.md`. Compared `PhaseReopen`, `ParallelRun`, `Release`, `RecordLock`, `SafeWrite`, and `ChangeRecord::Transaction` with the existing CLI, gate, and change-record layering, and with decisions D1 through D10, at `2be4aff`.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-008 | minor | `ChangeRecord::Transaction` | The multi-file write is staged, then committed as separate renames, handoffs first and metadata last. That is one lock and not one write. The order closes the previous failure (a history entry for a reset the handoffs do not show). It does not make the two halves atomic. See `functional.md`. | Same as REV-008 in `functional.md`: a kill or a raised error between renames leaves pending handoffs, no history entry, and a leftover temp file. | `.ai/rules/general.md` (invariants enforceable where appropriate); `.ai/rules/errors.md` (a failure must not look like success); AC-017 |

No other architecture finding. The CLI calls the new types. The guard still resolves the skill. The gate's meaning for a pending phase is unchanged (D3, REV-003). No new dependency was added. Errors are `TargetError` or `ArgumentError` and name the next command. Rescue of `StandardError` in `ParallelRun#run` and `Guard#decide` records or refuses the call. It does not turn the failure into a silent success.

The remediation tests for the rename order and the blank `discharged_at` have no red commit (VER-002). Remediation recorded why: the pre-commit hook runs `ci`, which fails while downstream evidence is stale, and the hook was not bypassed. The original slices still have the red commits named in IMPL-006. Verification re-confirmed `053562b`. That gap is recorded. It is not a new defect in the behavior.

## Deviation D2, accepted

`downstream` does not follow `on_code_change`, `on_blocked`, `on_rejected`, or `on_blocking_findings`. Following every edge from every later phase would reset verify whenever evaluate is reopened, because remediate is later in lifecycle order and its `next` is verify, which contradicts AC-001. Following `next` only from the reopened phase (and from phases reached by that edge) keeps AC-001 and AC-002. `downstream(judge)` is `[learn]`, so `on_rejected: intake` does not wipe the lifecycle. The rationale is in `05-implementation/decisions.md` and `deviations.md`. Approved.

## Conformance

Conforms with REV-008. Boundaries, dependency direction, and the recorded decisions match `.ai/rules/architecture.md`. D2 is the approved reading of downstream. The previous REV-001 (metadata renamed first) is not the code at this commit.
