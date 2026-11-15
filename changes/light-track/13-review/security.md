# Security Review

Standard: `.ai/rules/security.md`, graded against the threat model in `.ai/skills/adversarial-testing/SKILL.md`: an outside party reaching the change through what it exposes.

## Scope reviewed
- What the change exposes: one new `--track` value, a new comparison of reviewer-written paths, a count of remediation rounds, a sizing rule, and status text. No network surface, no sign-in, no data about a person, no credential.
- REQ-003 and REQ-004: whether any lock depends on the track.
- The intentional weakening: a light-track change runs no threat modeling, evaluation or attack. The maintainer's approval is recorded in `metadata.yml` under `human_decisions`, boundary "changes that intentionally weaken required controls", dated 2026-11-14.
- Verification checks' `protection` fields: the change touches no path listed under `access_control`, so `.ai/rules/access-control-parity.md` does not apply.
- Whether any evidence in this record was altered: both manifests match their files, and nothing under `changes/light-track/` outside `13-review/` differs from the sealed commit 2bd8a36.

## Assessment
- The specification lock, must-criteria approval, remediation cap, review gate and judgment gate do not read the track. The only track-dependent rule is `skippable?`, and `reached_lifecycle_end?` excludes judgment from it. EVAL-002 shows each lock failing on a light record with the same check as on a gated one.
- High risk: `track permitted` fails and `phase seal` commits nothing (EVAL-002).
- `normalize_path` only compares strings. It opens no file, so a path that leaves the repository reads nothing; such a path is refused.
- The round count errs toward counting more rounds, never fewer (REV-001). That parks a change early; it does not let one past the cap.
- `text_only_path?` excludes every `.yml` under `.ai/` and everything under the harness evals, so a settings change is never sized as text. A test holds it.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-005 | minor | `.ai/skills/final-judgment/` (not modified) | See functional.md: "attack is recorded as not run, not as a pass" is stated in three documents and instructed nowhere. It is the visible trace of the control the maintainer agreed to remove, so it should not depend on the judging session's reading. | | specification.md, Security requirements |
| REV-010 | minor, outside this change | `lib/soft_foundry/check.rb` | See architecture.md. Needs repository write access; follow-up only. | | review skill: repository-write weaknesses are follow-ups |

Follow-up, no severity: `track`, with `rules` and `risk`, is a line in `metadata.yml` that a party with repository write access can edit. The specification names it as a known gap and the attack skill now says so (REQ-008).

## Conformance
Conforms. No finding is blocking or major. No alteration of this record's evidence was observed.
