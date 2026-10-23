# Consolidated Review

Reviewed at `8575131b467d81c15b6773696225499aa576c29e` (attack rerun `7ca42a1` after the REV-001/REV-002 remediation). Rules loaded: the implementation baseline (general, architecture, security, errors, dependencies, observability, git, learned) plus ruby, testing, accessibility, policy-conformance, and infrastructure. No application or test code was changed in this phase. The verification suite recorded at `fb0bff7` was not rerun. Its first run failed one unrelated process test; the rerun of the same tree passed, and `tests.yml` records both.

## Functional

Does not conform. REV-001 (blocking): a `git.branch` recorded before the branch exists, then created at the phases-complete commit, hides later code on the checked-out branch, and the whole verify gate exits 0 for scoped and unscoped records (ATTACK-019, ATTACK-020). The remediation denied only the branch created at the evidence commit itself (ATTACK-017). REV-006 (minor): a recorded branch whose tip equals the evidence commit is measured at HEAD, so a stack cut from that tip stales the lower record. Claimed paths still do not enlarge verify size; that matches the maintainer decision and `.ai/policies/check-sizing.yml`, and it supersedes the locked REQ-009 sentence for those paths.

## Architecture

Does not conform on the measure rule. One classifier (`Scope`) and consumers that read the gate still match the plan. `tip_for`'s third clause is the same ancestry shape as a legitimate stacked branch (ATTACK-021), which is why REV-001 survives. The class comment in `sizing.rb` and the comment on `staleness_check` still describe the older rules; they do not change a result.

## Security

Does not conform. REV-001 is unrepaired THREAT-001. REV-003 (major): an active sibling scoped `**` makes another record's verify gate exit 0 after unrelated code lands; any status other than `closed` still claims (ATTACK-015, MIT-003). REV-004 (minor): a scalar `git:` crashes the gate with `TypeError` and exit 1. Attack cases 001 through 011, 013, 014, 016, and 017 stay denied.

## Accessibility

Conforms. CLI outcomes are words with stable prefixes; the browser shows scope and staleness as text. WCAG 2.2 1.4.1, 2.1.1, and 4.1.2 as applied, plus the command-line rules in `.ai/rules/accessibility.md`. No finding. This phase did not drive a browser.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are each `NOT_APPLICABLE`. The diff collects no personal data and adds no recipient. Policy text changes required: None.

## Infrastructure

N/A. No infrastructure as code in the diff. `.github/workflows/ci.yml` is unchanged. `.ai/rules/infrastructure.md` loaded; its plan, IAM, state, and secrets clauses do not apply.

## Operations

Does not conform, because REV-001 makes status, `ci`, and the scope advisory describe the frozen branch as current. REV-004 leaves the scalar-`git` failure without a next step. The REQ-018 advisories print and do not block, as specified. Observability is not a declared surface; phase 12 is still pending.

## Blocking findings

REV-001. A pre-recorded `git.branch` created later at a commit that strictly follows the evidence commit leaves scoped and unscoped evidence current after code lands on the checked-out branch, and `gate verify` exits 0 (`transcript3.txt` ATTACK-019, `transcript4.txt` ATTACK-020). Remediate, then rerun verify, evaluate, and attack. Another ancestry predicate will not separate this from the stacked branch; the evidence commit has to record that the ref did not resolve.

## Residual concerns

- REV-003 needs an explicit judgment decision if the claim rule stays as it is: one active `**` record, or any status other than `closed`, suppresses unclaimed-path staleness and the verify gate can pass.
- REV-006 is the other edge of the same predicate: tip equal to the evidence commit is not treated as the record's branch.
- The verification suite's first run on tree `537d8d15` failed `ProcessesTest#test_finds_a_real_running_process`; the rerun passed. `tests.yml` records the rerun as `passed` and keeps the failed log. The failure is unrelated to this diff and was not diagnosed.
