# Change Intake

## User intent
A real onboarding run against a specific repository (gov_pipeline) produced a genuinely rich agentic maturity assessment inside `.ai/repository.yml`, but nothing surfaced it: no terminal output worth reading, no separate report to open. The user wants the agent's findings reported for future handling, in two parts: a terminal summary printed on every run, and a persisted, human-readable report.

## Desired outcome
- Every assessment (fresh scan, fresh deep run, or showing an already-assessed repository's existing result) prints a short terminal summary: current level, what blocks the next level, a count of other recorded deficiencies.
- A persisted `.ai/maturity-report.md` renders the full capability findings already recorded in `.ai/repository.yml` — rationale, findings, evidence — into something meant to be read, not dug out of a YAML file.
- Critically: the "already assessed, skip re-scan" path must also show the summary and (re)write the report. Today it does neither, which means a repository already assessed (like gov_pipeline itself) would keep showing nothing on every future onboarding run even after this fix, unless the skip path is included.
- The report regenerates only when the underlying assessment actually changes, matching this tool's existing idempotency guarantee that a repeated run leaves no diff.

## Constraints
- Pure presentation over data scan/deep mode already produce; no new assessment logic, no change to what gets written to `.ai/repository.yml`.
- Must not break the "second run touches nothing" guarantee already established for `init`.

## Non-goals
- Turning findings into tracked issues (a beads integration or similar). Discussed as a related idea; deferred as a separate, bigger design decision.
- Fixing the `deep` mode subprocess reliability issue noted during triage (a session apparently had to perform the assessment "in compatibility mode" by hand rather than through the real `claude -p` subprocess path). Separate, distinct problem; not this change.

## Task classification
feature, application surface (one new library class, wiring into existing onboarding flow).

## Initial risk
low. Read-only rendering of already-recorded data, one guarded write to a new file inside `.ai/`, using the same hardened `SafeWrite` primitive as every other managed file.
