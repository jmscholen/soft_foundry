# Security Review

## Scope reviewed

Threats THREAT-001 to THREAT-010 and mitigations MIT-001 to MIT-010, the attack results at `4620188` (25 cases, 15 denied, 10 violated), and the code those cases name. Standard: `.ai/rules/security.md`. `.ai/repository.yml` declares no `access_control` globs, so `.ai/rules/access-control-parity.md` does not apply; verification's checks have nothing to state about a protection on a matched path.

No evidence-integrity check that already existed (staleness, specification lock, commit lineage, red evidence, content scan, verdict recorded) is removed. Review and judgment are not in `waivable_by_risk` or `default_waivers`. Close still requires a judgment. A flag on the reopen or seal command cannot pass the cap or the approval; only a `human_decisions` entry can, while the rules apply. The approved loosening is the tier, the cap, outside-change follow-ups, default low-risk waivers, and the documentation-only rerun. REV-001, REV-002, REV-003, and REV-004 are bypasses of those controls, not the loosening the maintainer approved.

THREAT-009 (the record lock around the refusal) and THREAT-010 (one `git log` per count) have no attack case, as specified. The refusal writes only `status`, inside the lock. The log is one call. Both match their mitigations on inspection.

THREAT-005 (demote an approved must) was denied: the specification lock fails and the approval check compares the lists (ATTACK-006). A decision at `rounds: 2` does not cover a later round (ATTACK-015). Emptying `phase_reopenings` leaves the commit count in place (ATTACK-012).

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | blocking | `phase_seal.rb`, `phase_reopen.rb`, `gate.rb` `rules_kept_check` | MIT-007 fails the first phase after the intake seal and does not stop the commands that start or seal a round. Current metadata is what `applies?` reads. A committed deletion before the intake seal is invisible to the note and to `rules kept`. | See REV-001 in `functional.md`. The third remediation seal succeeds with `rules` removed. Tiers, the approval, and the cap then skip. | REQ-017, THREAT-007, `.ai/rules/security.md` (a control is not disabled for convenience) |
| REV-002 | major | `process_rules.rb` `sealed_round_commits` | MIT-002 says both git history and `phase_reopenings` must be rewritten to lower the count, and that history is not editable metadata. `git.branch` chooses the history. The count drops with no rewrite. End to end on the change branch the extra round still cannot be sealed, because the branch check refuses while the names differ. The reopen has already reset the handoffs, and the review gate can pass. | See REV-002 in `functional.md`. ATTACK-002 and ATTACK-002c. | THREAT-002, MIT-002 |
| REV-003 | major | `phase_seal.rb` `hand_edited_metadata_keys` | MIT-008 says a risk changed after intake is named by the seal note, with the risk word left residual. A committed downgrade is not named. A high-risk change then takes the low-risk default waivers, including skipping threat modeling and attack. | See REV-003 in `functional.md`. ATTACK-014. | THREAT-008, MIT-008, `.ai/rules/security.md` |
| REV-004 | major | `gate.rb` `outside_change_check` | MIT-006 says a mark is refused when a named path changed in this change. The comparison does not normalize `./`, repeated slashes, a trailing space, a glob, or an absolute path, so a finding about modified code is accepted as outside the change. | See REV-004 in `functional.md`. ATTACK-007 and ATTACK-016. | THREAT-006, MIT-006 |
| REV-015 | minor | `phase_seal.rb` `hand_edited_metadata_keys` | MIT-001's note is the visible signal for a forged `human_decisions` entry. It compares uncommitted metadata with HEAD. Committing the forged must-criteria approval before `phase seal specify` leaves metadata clean, so the seal prints no note and `must criteria approved` passes. THREAT-001 is the accepted residual (a shell can write the file). The note does not survive the ordinary way of landing that write. | Forged approval committed as "wording", metadata clean at seal: no note, check passes (ATTACK-013). | MIT-001, THREAT-001 |

## Conformance

Does not conform. The structural checks for tiers, approval membership, person checks, and a blocked basis that names a should criterion or an outside-change finding do what their criteria say. The cap, the rules version, the risk word's audit note, and the outside-change path check do not hold on the inputs above. REV-001 is the one that lets a third remediation round seal with no person.
