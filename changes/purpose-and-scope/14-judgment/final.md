# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

## Commit judged
7296946d07a4e382622604fd652deb4d97f7eb06 (HEAD of `change/purpose-and-scope`, `Record purpose-and-scope review`).

Outside `changes/` this commit is identical to the implementation commit d944d07. The whole change, measured from the intake commit 49b2ae5, is 38 added lines in four files: `README.md`, `.ai/README.md`, `.ai/skills/adversarial-testing/SKILL.md` and `.ai/skills/review/SKILL.md`. Nothing under `lib/`, `exe/` or `test/` differs. This session read that diff in full.

## Requirements status
The record is under the convergence rules (`rules: 2`), risk low, type docs. The three must criteria were approved by a person under `human_decisions`.

| Criterion | Tier | Status | Basis |
| --- | --- | --- | --- |
| AC-001 | must | met | CHECK-001, EVAL-001, EVAL-002, EVAL-005; read in the diff by this session. `Purpose` is the first section after the title in both README files and carries the three statements. |
| AC-002 | must | met | CHECK-001, EVAL-003, EVAL-005; read in the diff. The attacker is named as an outside party, the nine classes are listed in the order of REQ-002, and repository-write editing is out of scope and noted as a follow-up. |
| AC-003 | must | met | CHECK-001, EVAL-004, EVAL-005; read in the diff. A finding that needs write access to the repository is never graded blocking or major and is recorded as a follow-up. |
| AC-004 | should | met | CHECK-001, EVAL-001. |
| AC-005 | should | met | CHECK-001, CHECK-002, EVAL-006, and the accessibility review (conforms, no advisory). |
| AC-006 | should | met | CHECK-001 to CHECK-004, EVAL-007. |

Every criterion is named by a verification check and an evaluation journey. None is set aside.

## Verification
Complete at 4b693c7, current for the judged commit (no code change since). Four checks pass: the content script (45 assertions), `soft-foundry check`, `soft-foundry ci` (35 harness evals passed, 1 live case skipped), and the full suite (935 runs, 0 failures, 0 errors, 0 skips) in a clean clone with provider keys unset. Two runs that did not finish cleanly are preserved and explained in `06-verification/results.md`: a `ci` run that failed on a ref that exists only in the clone, and a suite run cut off by the session time limit and rerun to completion. Neither is a failure of the change. No check carries a failing-test-first commit, which is expected for a text-only change.

## Evaluation
Complete at d272a5f, current. Seven journeys pass; all six criteria are met as a reader finds them. Accessibility observations are recorded and pass. Four advisory findings, all minor, none an unmet criterion (EVAL-F1 to EVAL-F4).

## Attack
Not run. At risk low the attack phase is stepped over by default (`default_waivers` and `waivable_by_risk` in `.ai/workflow.yml`; the intake gate's `waivers permitted` check lists it), and the record names it under neither `skipped_phases` nor `run_phases`. The change adds no code and exposes nothing an outside party can reach, so under the threat model this change itself writes there is no surface to attack. The absence of attack evidence is carried as residual risk R-3, not counted as a pass.

## Documentation
The user-documentation and FAQ-index phases did not run; both are optional. The change is itself documentation, and evaluation read it as an adopter and as an agent would.

## Observability
Not run; optional. No runtime behavior changes. The operations review conforms; rollback is a revert of d944d07.

## Review findings
Complete at 5844763, current. No blocking or major finding. Functional, architecture, security, accessibility and operations conform; policy conformance and infrastructure are not applicable. Eight minor findings, each carried forward, none a reason to withhold approval under the convergence rules:

- REV-001: the new review sentence also caps the grade of an alteration a reviewer actually sees in the record under review. This is the cost of the narrowing the maintainer approved. Residual risk R-1.
- REV-003: the attack skill says the guard and the specification lock cover repository-write tampering, which says more than is true. Residual risk R-2.
- REV-002, REV-004, REV-005, REV-006: wording follow-ups for one later documentation change (the sentence "Everything in between runs without them", whether the nine classes are the whole list, one named place for repository-write follow-ups, two openings and a stale milestone section in `README.md`).
- REV-007: guard behavior seen during the evidence sessions, not caused by this change. For a person. Residual risk R-6.
- REV-008: both `human_decisions` entries were typed in by the agent session. For the maintainer to confirm on acceptance. Residual risk R-4.

Remediation did not run and no round was used; the remediation cap does not apply.

## Residual risk
Six items, listed in `residual-risk.md`. In short: the approved narrowing of attack and review (R-1), the known gap in what the guard and lock cover (R-2), no attack evidence (R-3), approvals recorded by the agent (R-4), review and judgment on the same provider and model as the implementation (R-5), and guard anomalies in this worktree that a person should look at (R-6).

What the maintainer is asked to do on acceptance: confirm the two approvals under `human_decisions` (R-4), and check the local guard override and guard log (R-6). The change is stacked on `change/process-speed` (pull request 63) and merges after it.

Gate state at judgment: with the tool in this worktree (`ruby -Ilib exe/soft-foundry change status`) every completed phase gates ok. The globally installed `soft-foundry` 0.23.0 does not know the default waivers and reports `predecessor complete` failures for specification, implementation and review; that is the installed version being older than this branch, not a defect of the record.
