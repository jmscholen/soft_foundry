# Specification

## Intent
Give Soft Foundry's own changes, and any change that opts in, a shorter path: specification, implementation, the test suite, one review, judgment. Fix two defects carried from process-speed and stop a text-only change from paying for a full suite run. Requirements are REQ-001 to REQ-012 in requirements.yml.

## Personas and authorization boundaries
- The maintainer creates a change and chooses its track.
- An agent works the phases the track requires.
- A person still approves the must criteria and decides at the remediation cap. The light track changes neither.

## Functional behavior
- REQ-001, REQ-002: the light track and what the gate asks of a record on it.
- REQ-005: outside-change paths are normalized; absolute paths, paths leaving the repository and globs are refused.
- REQ-006: an unfinished remediation is not a round; messages say rounds.
- REQ-008: two wording fixes in the review and adversarial-testing skills.
- REQ-012: `change status` shows the track and labels phases the track makes optional.

## Accessibility
REQ-010. New output reads correctly with colour off and symbols removed. Documentation keeps heading order.

## Data and consistency
The track is recorded in `metadata.yml` at creation, as today. No new record fields.

## Failure behavior
REQ-011. Gated and iterative records, and records created before this change, gate as before. An unknown track name is refused with the list of defined tracks.

## Security requirements
REQ-003 and REQ-004. The light track removes phases, not locks: the specification lock, must-criteria approval, the remediation cap, review and judgment all apply. High risk cannot use it.

The light track removes threat modeling, evaluation and attack for changes that opt in. That intentionally weakens a required control and needs the maintainer's recorded approval. A change on the light track has no attack evidence; judgment records attack as not run, not as a pass.

Known gap, unchanged: `track`, like `rules` and `risk`, is a line in `metadata.yml` that a party with repository write access can edit. That is outside the attack threat model (purpose-and-scope) and belongs to the guard follow-up.

## Privacy and security policy conformance
Nothing the policies cover changes. The repository profile records them as not applicable.

## Performance and resource limits
REQ-007. A change that modifies only documentation, its own record and control-plane Markdown is sized at the smaller verify size. The control plane check and harness evals still run.

## Infrastructure implications
None.

## Observability expectations
REQ-012. A person can see from `change status` which track a record is on and why a phase did not run.

## Acceptance criteria
AC-001 to AC-009 in acceptance-criteria.yml. Must: AC-001, AC-002, AC-003. Should: AC-004 to AC-009. Person check: PC-001.
