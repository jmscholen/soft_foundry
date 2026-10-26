# Architecture Review

## Scope reviewed

Loaded `.ai/rules/architecture.md`, `.ai/rules/general.md`, `.ai/rules/ruby.md`, `.ai/rules/errors.md`, `.ai/rules/dependencies.md`, `.ai/rules/git.md`, `.ai/rules/learned.md`, and `.ai/rules/testing.md` (the implementation baseline plus the discovered Ruby and testing rules). Compared the new types with the existing CLI, gate, and change-record layering, and with decisions D1 through D10.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | `ChangeRecord::Transaction` | The multi-file write is staged, then committed as separate renames with metadata first. That is not one write. See the functional review for the input and the wrong result. | Same as REV-001 in `functional.md`: a kill between renames leaves a history entry for a reset the handoffs do not show, and close can succeed. | `.ai/rules/general.md` (invariants enforceable where appropriate); `.ai/rules/errors.md` (a failure must not look like success); AC-017 |

No other architecture finding. The new behavior sits in `PhaseReopen`, `ParallelRun`, `Release`, `RecordLock`, and `SafeWrite`, and the CLI calls them. The guard still resolves the skill. The gate's meaning for a pending phase is unchanged (D3, REV-003). No new dependency was added. Errors are `TargetError` or `ArgumentError` and name the next command. Red commits for the new tests are recorded by implementation (IMPL-006); verification re-confirmed `053562b`.

## Deviation D2, accepted

`downstream` does not follow `on_code_change`, `on_blocked`, `on_rejected`, or `on_blocking_findings`. Following every edge from every later phase would reset verify whenever evaluate is reopened, because remediate is later in lifecycle order and its `next` is verify, which contradicts AC-001. Following `next` only from the reopened phase (and from phases reached by that edge) keeps AC-001 and AC-002. `downstream(judge)` is `[learn]`, so `on_rejected: intake` does not wipe the lifecycle. The rationale is in `05-implementation/decisions.md` and `deviations.md`. Approved.

## Conformance

Conforms with REV-001. Boundaries, dependency direction, and the recorded decisions match `.ai/rules/architecture.md`. D2 is the approved reading of downstream.
