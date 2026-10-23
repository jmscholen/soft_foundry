# Consolidated Review

Reviewed at `85edc8e85da71c4e55d3336507e688b779b6af5d` (attack rerun after the ATTACK-F-006 repair). Rules loaded: the implementation baseline (general, architecture, security, errors, dependencies, observability, git, learned) plus ruby, testing, accessibility, policy-conformance, and infrastructure. No application or test code was changed in this phase. The verification suite at `2294f86` (632 runs, 0 failures) was not rerun.

## Functional

Does not conform. REV-001 (blocking): a `git.branch` recorded before the branch exists, then created at the evidence commit, hides later code on the checked-out branch and the whole verify gate passes. REV-002 (major): a path claimed by another active record does not enlarge verify size, which contradicts `.ai/policies/check-sizing.yml` and REQ-009. REV-005 (minor): the README sizing paragraph omits unclaimed paths and `git.branch`.

## Architecture

Conforms with REV-001 and REV-002. One classifier (`Scope`), consumers read the gate, and the branch-tip rule from `.ai/rules/learned.md` is the mechanism REV-001 abuses. Sizing and the advisory disagree on claimed paths.

## Security

Does not conform. REV-001 is unrepaired ATTACK-F-007 (THREAT-001). REV-003 (major): an active sibling scoped `**` makes another record's verify gate pass after unrelated code lands; closing the sibling makes that change stale (ATTACK-015, MIT-003). REV-004 (minor): a scalar `git:` crashes the gate with `TypeError` and exit 1 (ATTACK-F-008). Attack cases 001 through 011, 013, 014, and 016 stay denied.

## Accessibility

Conforms. CLI outcomes are words with stable prefixes; the browser shows scope and staleness as text. WCAG 2.2 1.4.1, 1.4.3, 2.1.1, and 4.1.2 as applied, plus the command-line rules in `.ai/rules/accessibility.md`. No finding. This phase did not drive a browser; the conclusion is from `app.js`, `app.css`, and the CLI.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are each `NOT_APPLICABLE`. The diff collects no personal data and adds no recipient. Policy text changes required: None.

## Infrastructure

N/A. No infrastructure as code in the diff. `.github/workflows/ci.yml` is unchanged. `.ai/rules/infrastructure.md` loaded; its plan, IAM, state, and secrets clauses do not apply.

## Operations

Does not conform, because REV-001 makes status and the scope advisory describe the frozen branch. REV-004 leaves the scalar-`git` failure without a next step. The three REQ-018 advisories work when the measure is the real branch. Observability, user-documentation, and FAQ phases are still pending.

## Blocking findings

REV-001. A pre-recorded `git.branch` whose branch is created later at the evidence commit leaves scoped and unscoped evidence current after code lands on the checked-out branch, and `gate verify` exits 0 (`transcript3.txt`, ATTACK-019). Remediate, then rerun verify, evaluate, and attack.

## Residual concerns

- REV-003 needs an explicit judgment decision if the claim rule stays as it is: one active `**` record, or any non-`closed` status, suppresses unclaimed-path staleness and the verify gate can pass.
- REV-002 was an intentional repair of EVAL-F-001 so a sibling's commits do not fail a current record's size check (AC-018). The policy file, the plan, and REQ-009 still describe the stricter size. The two texts need one owner.
- A scoped in-scope change may omit `full_suite` and still pass verify: the check skips with "owed before merge" (plan step 5). Nothing at close fails, and no advisory fires unless shared core was touched. That matches the plan and leaves REQ-012 as a note in the skip line.
- A recorded `full_suite` outcome remains a claim (REQ-008). Ignored files outside the code globs do not refuse citation (MIT-005). Unscoped git failures still return an empty path list (REQ-004, IMPL-006).
- `10-user-documentation`, `11-faq-index`, and `12-observability` are pending. The surface flags that make the last of those applicable are false.
