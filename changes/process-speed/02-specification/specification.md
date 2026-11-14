# Specification

## Intent
Make the lifecycle converge. A change loops through remediation at most twice before a person decides; a person approves the criteria that can block, before implementation starts; checks only a person can make leave the criteria and become release items; findings about code the change does not touch become follow-ups; and the loop is lighter where risk and the diff allow. Requirements REQ-001 to REQ-017 (requirements.yml), criteria AC-001 to AC-019 (acceptance-criteria.yml).

## Personas and authorization boundaries
- **Maintainer (a person).** The only one who may record a human_decisions entry: approving the must list (REQ-005), answering the remediation cap (REQ-003), and choosing a documentation-only reopen (REQ-012). Recording a decision an agent was not given is fabricating evidence (`.ai/policies/human-boundaries.yml` never_autonomous).
- **Agent sessions.** Write their own phase's files as today. A phase-run session already may not reopen phases (`SOFT_FOUNDRY_PHASE`); that refusal is unchanged and now also covers the documentation-only option.
- **The tool.** Counts rounds, refuses the fourth reopen, parks the change, and checks tiers, caps, approval and the blocked basis. Every check is structural: it reads fields the record asserts and never judges whether a claim is true.

## Functional behavior
1. **Rules version (REQ-001).** `change new` writes a rules version into metadata.yml. A record without one is legacy: each new check reports skip, "legacy record", the way closed and released records report "not re-gated".
2. **Round cap (REQ-002, REQ-003).** A round is one seal of 09-remediation (counted from the record's history; plan decides between `Record <slug> remediate` commits and the remediate entries in phase_reopenings, and both must agree on the worked example). With two rounds sealed, `phase reopen remediate` and any reopen whose reset includes remediation, manual or automatic, is refused: nothing resets, status becomes awaiting_human, and the output names the boundary "remediation cap" and the decisions accept_residual, narrow and reject. A human_decisions entry for the current count lets one more round through. The review and judgment gates fail a record whose round count exceeds the limit without that entry. The limit lives in .ai/workflow.yml.
3. **Tiers and cap (REQ-004).** Each criterion on a new-rules record carries `tier: must | should`. The specify gate fails a missing or unknown tier and a must count over the cap for the declared risk (.ai/workflow.yml; low 3, medium 8, high 15).
4. **Approval (REQ-005).** The specify gate fails until human_decisions holds `boundary: must criteria approval` with `criteria:` equal to the set of must ids. Because the gate fails, `phase seal specify` refuses.
5. **Coverage by tier (REQ-006).** The judgment criteria check fails only for an uncovered must criterion; an uncovered should criterion is a warning.
6. **Person checks (REQ-007).** `person_checks:` in acceptance-criteria.yml lists checks only a person can make. They are never criteria. `change release` adds one release item per person check not already named.
7. **Blocked basis (REQ-008).** A BLOCKED final.md on a new-rules record requires `blocked_by:` in 14-judgment/evidence.yml; each entry names an unmet must criterion or a review finding with severity blocking and a failure, not marked outside_change.
8. **Outside the change (REQ-009).** A review or attack finding may carry `outside_change: true` with `follow_up:`; it never blocks and appears as a follow-up advisory. A finding marked outside_change without follow_up fails the review gate.
9. **Default low-risk waivers (REQ-010).** On a low-risk new-rules record the phases waivable at low risk are stepped over unless named under `run_phases:`. The waivers check lists them as default waivers.
10. **Documentation-only sizing (REQ-011).** When every changed path is documentation (DOCS, top-level Markdown, the change's own record), sizing returns the smaller size for verify, evaluate and attack, with the rule named in its reasons.
11. **Documentation-only reopen (REQ-012).** `phase reopen remediate --docs-only` resets remediate and document through learn, keeps verify, evaluate and attack complete, and records `docs_only: true` in the reopen entry. Sealing that remediation is refused when any non-documentation path changed since the reopen's from_commit.
12. **Skill text (REQ-013).** As REQ-013 lists, per skill.

## Accessibility
surfaces.accessibility is true: the change adds command-line refusals, warnings and advisories. REQ-016 applies `.ai/rules/accessibility.md` command-line rules to each new line (AC-019). No visual UI changes; the `ui` page shows the parked status through the existing snapshot fields.

## Data and consistency
New record fields: metadata `rules` (version), `run_phases`; acceptance-criteria `tier`, `person_checks`; judgment evidence `blocked_by`; finding `outside_change`, `follow_up`; reopen entry `docs_only`; human_decisions boundaries "remediation cap" (with `decision`, `rounds`) and "must criteria approval" (with `criteria`). New control-plane keys in .ai/workflow.yml: the round limit, must caps by risk, the default-waiver rule. Reopen refusal and parking are applied in one record transaction or not at all, as PhaseReopen applies resets today. Legacy and closed records are read, never rewritten.

## Failure behavior
- A refused reopen changes no handoff; the only metadata write is status awaiting_human, done in the same transaction as the refusal decision.
- A malformed new workflow key fails `check` with the key named, and the gate fails closed rather than treating the cap as unlimited.
- A human_decisions entry with an unknown decision word, a missing rounds count, or criteria that do not parse does not satisfy the check, and the failure names the field.
- A documentation-only seal that cannot compute the diff (missing from_commit, git error) is refused, never allowed.

## Security requirements
REQ-017: no evidence-integrity check is removed or weakened; review and judgment stay unwaivable; close still needs a final judgment; only a human_decisions entry passes the cap or the approval. The threat model enumerates forgeries of those entries, of run_phases and docs_only, and of the round count (deleting phase_reopenings entries, squashing seal commits).

## Privacy and security policy conformance
Nothing the application collects, shares, retains, protects or promises changes: Soft Foundry publishes no privacy policy, security policy or terms (all NOT_APPLICABLE in .ai/repository.yml), and this change alters only the governance process. surfaces.policy is false.

## Performance and resource limits
Round counting reads metadata and at most one `git log` over the record's history per gate run, within the existing single observation per evaluation. No new check runs the suite. REQ-011 and REQ-012 reduce work; DISC-001 records the 18-minute suite as context, not a target of this change.

## Infrastructure implications
None. No deployed service, database or IaC.

## Observability expectations
The record is the observability surface: the reopen refusal, the parked status, default waivers, follow-up findings and the docs-only flag are visible in metadata.yml, `change status`, `change summary`, the advisories and the `ui` snapshot. No runtime telemetry applies (surfaces.observability false).

## Acceptance criteria
AC-001 to AC-019 in acceptance-criteria.yml, each tiered. Must: AC-001, 002, 004, 005, 006, 007, 008, 009, 010, 015, 017, 018 (12). Should: AC-003, 011, 012, 013, 014, 016, 019 (7). Person check PC-001 is a release item, not a criterion. Each criterion holds the change only to the case it names; nothing in this specification makes every statement in the code, the skills or the documentation binding.
