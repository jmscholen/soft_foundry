# Architecture Review

## Scope reviewed
- How the change was delivered: one maintainer commit (`b9f4d7c`) for the three files no skill may write, made before the record existed, then the lifecycle for the README and the user page. `05-implementation/deviations.md` names review as an approver of both deviations.
- Where the guard's description now lives: the header of `.ai/policies/enforcement.yml` (protected policy, the canonical statement), the README guard section (the reference text for a person), `docs/user/guard-hook.md` (the task-by-task version), `docs/user/README.md` (the index), and the twelve FAQ records for the index phase.
- The hook entries themselves: both commands prefer the checkout's own code (`ruby -Ilib exe/soft-foundry`) and fall back to the installed gem, the shape `Hooks::GUARD_COMMAND` writes everywhere.
- `.ai/README.md`, `AGENTS.md`, and the rules under `.ai/rules/` for statements about the guard that the new text might contradict.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-GDH-009 | minor (informational, accepted) | `05-implementation/deviations.md` 1 and 2 | Deviation 1 (the maintainer commit outside the lifecycle) is the boundary factory-readiness set: no skill's write set covers the guard's own configuration, protected policy, or harness material, and the guard refuses them. The commit is labelled as a maintainer commit, lists its reason, and is read by verification, evaluation and this review as REQ-GDH-001 to 003. Deviation 2 (the session copying intake's waivers and the accessibility surface into `metadata.yml`) follows the release-0-23-0 precedent. Both accepted. | None. | `.ai/policies/skill-permissions.yml` (protected paths), `.ai/rules/general.md` (changes outside scope documented as deviations) |

No further architecture finding. The description is in three places by design (policy header, README, user page), and the three agree with one another on every point checked; the one claim they share that does not hold (REV-GDH-001) is a code behaviour, not a disagreement between the texts. `AGENTS.md` still says "Bash is checked against deny sets only", which remains an accurate summary for an agent (the shell check never consults the write set) and matches the comment at `guard.rb` 472 to 473. No rule under `.ai/rules/` describes the guard. The documentation index `docs/user/README.md` records provenance (introducing change, verifying change, journeys) as that directory's own README requires.

## Conformance
Conforms. The change adds no module, dependency, or interface, and places each text where the repository already says it belongs.
