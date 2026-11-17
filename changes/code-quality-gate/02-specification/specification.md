# Specification

## Intent
Add a phase gate in which a reviewer acting as a staff software engineer reads the change's code for quality: whether it meets the need, whether it is the simplest sufficient design, whether it repeats existing logic, whether it performs acceptably on the paths it serves, and whether the next engineer can change it safely. The maintainer's decisions of 2026-11-15 fix its position (after verify), its authority (block on a concrete cost in a named class) and where it is required (medium and high risk). On 2026-11-16 the maintainer revised the last: the gate is optional, and a repository turns it on, automatically for Ruby and similar scripting languages. That supersedes "required at medium and high risk" in 00-intake/request.md wherever the two differ.

## Personas and authorization boundaries
- The person building an application with Soft Foundry, who approves the specification and accepts the result. They read the quality findings at acceptance.
- The agent sessions that run phases. The quality session reads the code and the record and writes only its own directory (REQ-003).

## Functional behavior
- The phase and its place in the lifecycle: REQ-001.
- What the reviewer asks: REQ-002. The six questions are fit to need, simplest design and fit to conventions, repeated logic, performance and resource use on real paths, reliability under concurrency, retries and partial failure, and clarity for the next engineer. The reviewer traces from the changed lines, and each finding gives a file and line, its trigger, the evidence, the smallest remedy and how to verify it.
- Framework detail: REQ-013. The skill is framework-neutral; `.ai/rules/rails.md` carries the Rails review decisions.
- Repairing a quality finding: REQ-014, in the remediation skill.
- Where it is required: REQ-004. The gate is optional unless the repository's profile turns it on (`quality_gate.enabled` in `.ai/repository.yml`). Onboarding turns it on when it detects Ruby, Python, JavaScript, TypeScript or PHP; a person may set it either way. Where it is off, no change is asked for it. The table is for a repository where it is on. A change may always run it by naming it under `run_phases`.

| Track | Low risk | Medium risk | High risk |
| --- | --- | --- | --- |
| gated | stepped over by default | required | required |
| iterative | stepped over by default | required | not available (high risk is gated) |
| light | optional | optional | not available (high risk is gated) |

- What can block: REQ-005. The five classes are duplication (logic that exists elsewhere and will drift), performance (a cost on a path the feature exercises), simpler_design (a simpler design meets the specification), unmet_need (a need the specification states that the solution does not meet) and reliability (wrong data or a lost or repeated side effect under a concurrent request, a retry or a failure part-way through). A blocking finding names its class and its concrete cost. Anything else is major or lower and never blocks.
- What happens next: REQ-006.
- Evidence binding and staleness: REQ-007.
- Fresh session and provider preference: REQ-008.
- Review and judgment: REQ-009.

## Accessibility
REQ-011. Status output states the phase and any skip reason in words. Documentation uses ordered headings, lists and tables.

## Data and consistency
A record's `rules` number tells whether the phase is asked of it (REQ-004). Records created earlier keep their number and are not rewritten.

## Failure behavior
- A blocking finding that is not well formed fails the quality gate with a message naming the finding and what is missing (REQ-005).
- A round beyond the remediation cap is refused as today (REQ-006).

## Security requirements
REQ-003. The phase cannot write code, tests, documentation, the control plane or another phase's evidence, and cannot read harness evals.

## Privacy and security policy conformance
Nothing the tool collects, shares, retains, protects or promises changes.

## Performance and resource limits
The phase adds one fresh session to a medium or high risk change. It runs no test suite of its own.

## Infrastructure implications
None.

## Observability expectations
`change status` shows the phase (REQ-010).

## Acceptance criteria
AC-001 to AC-004 are must; AC-005 to AC-012 are should. PC-001 is the maintainer's check after merge.
