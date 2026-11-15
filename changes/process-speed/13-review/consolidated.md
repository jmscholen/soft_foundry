# Consolidated Review

Reviewed at `d6ed77b077bbbe8a9963f082cfad89706e920ad3` (code identical to implementation `a37d580`). This record is legacy: it has no `rules: 2`, so the new checks do not gate it. The findings are about what the code does to a record that declares the rules.

## Functional

Does not conform. The must criteria's named cases pass on verification and evaluation evidence, including the cap refusal while `rules: 2` is present. REV-001: deleting `rules` and committing that deletion makes `phase seal remediate` succeed after two `Record` remediation commits. Confirmed on a throwaway repository on 2026-11-14 (refused with the rules present, sealed after they were removed). REV-005: a refused, unsealed remediation counts as a sealed round and the message says so.

## Architecture

Does not conform. `ProcessRules` is a single module and the callers use it. The cap is not one invariant. Current metadata switches it off at reopen and seal (REV-001). `git.branch` chooses which history the round count reads (REV-002). `Git#count_subject` turns a failed `git log` into zero rounds (REV-013).

## Security

Does not conform. MIT-007 does not stop a third remediation seal (REV-001). MIT-002's "history only" count is lowered by `git.branch` (REV-002). MIT-008's note does not see a committed risk downgrade, so a high-risk change gains the low-risk waivers, including skipping attack (REV-003). MIT-006 accepts spellings of a modified path as outside the change (REV-004). A forged approval committed before the specify seal prints no note (REV-015); THREAT-001 remains the accepted residual. Existing evidence-integrity checks are still in place. Review and judgment stay unwaivable.

## Accessibility

Conforms with advisories. No visual UI. Command output keeps outcome words without color. REV-012: the cap refusal is one line of 506 characters. REV-014: a reopen after the change is already parked does not repeat the three decisions. Both cite `.ai/rules/accessibility.md` command-line rules. They do not withhold this handoff.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are `NOT_APPLICABLE`. The diff adds no collection, recipient, retention change, or published promise. Policy text changes required: None. REV-016 records that the application still publishes no security policy; this change did not create that gap.

## Infrastructure

N/A. No Infrastructure as Code is present or modified. `surfaces.infrastructure` is false.

## Operations

Does not conform, because the parked-status message reports a false seal count (REV-005). Session start is refused while `awaiting_human`. Person checks are copied onto `change release`. The product-documentation, FAQ, and observability phase directories are still unused templates. The operator text reviewed is the committed `README.md` and `docs/user/converging-changes.md`.

## Blocking findings

REV-001. A record that has sealed two remediation rounds can seal a third after `rules` is deleted from `metadata.yml`. The intake gate's `rules kept` check is not what reopen or seal consults, and a deletion committed before the intake seal makes that check skip as well.

Workflow `transitions.review.on_blocking_findings` returns this change to remediate. This record is not under `rules: 2`, so that routing is the workflow's, not the new cap.

## Majors remediation should fix

REV-002 (`git.branch` lowers the round count and permits the reopen), REV-003 (a committed risk downgrade is silent and enables default waivers), REV-004 (outside-change path spellings), REV-005 (an unsealed remediation counts as sealed, and the message says "sealed").

## Residual concerns

- REV-006: the docs-only way out fails while the remediate handoff is pending. A later reopen, once the handoff is complete, clears it.
- REV-007: malformed `rounds` or `decision` values fail closed without naming the field. The prose says "round 3" and the field to write is `rounds: 2`.
- REV-008: AC-012 still lists specify as a default waiver. DEV-004, the maintainer's decision, excludes it. Judgment should accept that deviation or record a requirement change. The code should not start waiving specify.
- REV-009: the attack skill does not say non-must findings are advisory (AC-016, should).
- REV-010: user docs do not name `rules kept`.
- REV-011: the follow-up advisory is printed even when the check rejects the mark, and it claims the code is outside the change.
- REV-012 and REV-014: accessibility advisories, above.
- REV-013: `git log` failure counts as zero rounds.
- REV-015: a hand-committed forged approval skips MIT-001's note. Accepted residual for the forgery itself.
- REV-016: no published security policy, outside this change (`outside_change`, follow-up is a documentation change). Not introduced here.
- REQ-011 counts `AGENTS.md` and `CLAUDE.md` as documentation, so a documentation-only remediation can edit the agent bootstrap while verify, evaluate, and attack stay complete (ATTACK-005c). The specification requires that. Judgment can exclude the pointer files in a follow-up. It is not a defect against this specification.
- An empty must list still needs an approval entry whose `criteria` is empty (EVAL-001). That matches REQ-005's "exactly the set".
- `blocked basis` accepts any must id and does not check that it is unmet (EVA-005). The specification limits the gate to structure. Judgment has to compare `blocked_by` with the evidence.
