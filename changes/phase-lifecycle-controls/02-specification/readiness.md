# Specification Readiness

## Blocking unknowns
None. Every discovery unknown was decided in the specification: history key (`phase_reopenings`, REQ-004), concurrent skill resolution (session marker, REQ-013), downstream computation (REQ-002), what discharges a released item (`change discharge`, REQ-019), consumer treatment of released (REQ-021), judgment still required for release (REQ-018), commit binding for parallel runs (REQ-015). Non-blocking design choices are left to planning (lock mechanism, marker variable name, message wording, how the guard obtains the isolated list). `.ai/harness-evals/cases/` and `.ai/policies/` were not readable in this phase (DISC-005); planning and verification must read them before adding cases.

## Untestable criteria
None. AC-001 to AC-051 are given/when/then fixtures runnable with stub shells and fixture repositories; the performance criterion (AC-034) uses fixed stub durations, and the concurrency criterion (AC-028) uses repeated runs.

## Ready for threat modeling and planning
Yes. Security-relevant surfaces for the threat model: the session marker and guard resolution (REQ-013), reopen/release/discharge refusal inside sessions (REQ-007, REQ-018), `--env` secrecy (REQ-012), `released` as a skip route (REQ-018), and lock and atomic-write behavior (REQ-014).
