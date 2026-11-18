# Change Intake

## User intent
On 2026-11-15 the maintainer asked for a new phase gate: a staff software engineer review for code quality. In the maintainer's words: "is this the best implementation, did the solution meet the needs while also staying DRY, and other performance criteria."

The existing review phase covers functional behavior, architecture, security, accessibility, policy, infrastructure and operations in one session at the end of the lifecycle. It names coding standards but has no section, checklist or gate for code quality, and it runs after evaluation and attack, so rework it asks for reruns those phases.

## Desired outcome
- A new lifecycle phase, the code-quality review, that runs after verification and before evaluation. It runs in a fresh session and writes only its own directory.
- The reviewer acts as a staff software engineer and answers, with evidence from the code:
  - Does the solution meet the need the specification states, without building more than was asked?
  - Is this the simplest design that meets it, and does it fit the conventions of the code around it?
  - Does it repeat logic that already exists in the repository or within the change (DRY)?
  - Does it have a performance or resource problem on a path the feature really exercises?
  - Are names, structure and tests clear enough for the next engineer to change safely?
- Authority (maintainer, 2026-11-15, "Block on serious only"): a finding blocks only when it names a concrete cost in one of four classes: duplicated logic that will drift, a performance problem on a real path, a simpler design that meets the specification, or a stated need the solution does not meet. Everything else is reported and carried to review and judgment. A blocked change goes to remediation and the round counts toward the remediation cap.
- Where it applies (maintainer, 2026-11-15, "Medium and high risk"): required on the gated and iterative tracks at medium and high risk; stepped over by default at low risk; optional on the light track. It can still be run on request where it is not required.
- Position (maintainer, 2026-11-15, "After verify").

## Constraints
- Records that already exist are not asked for the new phase and gate exactly as they do today.
- The phase does not repair code. Rework is remediation's job.
- It adds one fresh session to a medium or high risk change. The maintainer's budget is 1 to 3 hours from approved specification to result.
- Evidence phases run with `--shell claude` (maintainer, 2026-11-14).
- Edits under `.ai/` and to `metadata.yml` need the maintainer's local guard override.

## Non-goals
- Changing what the existing review phase covers, beyond telling it not to repeat the code-quality review and to read its findings.
- Automated metrics (complexity scores, duplication detectors, benchmarks). The phase is a reviewer's reading of the code; it may run tools the repository already has.
- Application-type paths and the check catalog.
- The parked light-track fixes and guard follow-ups.

## Task classification
feature. A new phase, its skill, its gate checks and its documentation.

## Initial risk
medium. The change alters the lifecycle every application repository receives on its next `soft-foundry init`: a new required phase at medium and high risk that can send a change to remediation. It removes no lock.
