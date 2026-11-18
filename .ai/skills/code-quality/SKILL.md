# Code-Quality Review

Read the change's code as a staff software engineer who will own it after it ships. Decide whether it is a sound implementation of what the specification asks for. This phase does not repair code, and it does not alter tests, documentation or another phase's evidence: it writes findings to `06a-code-quality/`, and remediation does the rework.

The phase runs after verification, so the checks already pass. Passing checks are not the question here. The question is whether the next engineer inherits a solution that fits the need, is no more complicated than it has to be, does not repeat what already exists, and holds up under load and under failure.

## Trace the behavior

Start at the changed lines: the diff from the commit the change began at to the commit under review. Read the specification and its acceptance criteria first, then the code.

- Trace each changed entry point to its callers, the data it writes and its side effects. Include secondary callers such as background work and scripts.
- Establish what must stay true, from the specification, database constraints, existing checks and the callers in the repository. Where an assumption matters, check it against the surrounding code. Write an unresolved business rule as a question, not as a finding.
- Separate what this change introduced from what was already there. A finding about code the change did not modify is marked `outside_change: true` in the handoff, with the `paths` it concerns and a `follow_up`; it never blocks this change.
- Load the rule files that apply to the repository's languages and frameworks (`.ai/rules/`, selected by discovery and the profile in `.ai/repository.yml`), as implementation and review do. Framework-specific review decisions live there, not in this skill.

## The six questions

Answer each in its own file, with the files and lines the answer rests on.

1. **Fit to need** (`fit.md`). Does the solution meet the need the specification states, without building more than was asked?
2. **Design** (`design.md`). Is it the simplest design that meets the specification, and does it fit the conventions of the code around it? Name which object owns each decision and which callers must agree. The size of a class, or the absence of a pattern, is not a defect on its own.
3. **Duplication** (`duplication.md`). Does it repeat logic that already exists in the repository or within the change? Two places that happen to look alike are not duplication; two places that must change together are.
4. **Performance** (`performance.md`). Is there a performance or resource problem on a path the feature exercises? Follow each query or loop from where it is built to where it is used, and say how the work grows with input size. Use a measurement when the repository gives you one, and label an estimate as an estimate.
5. **Reliability** (`reliability.md`). Does it stay correct under concurrent requests, retries and a failure part-way through? Walk through two concurrent requests where uniqueness, inventory or a state change matters. Walk through a failure just after an external side effect and before it is recorded locally.
6. **Clarity** (`clarity.md`). Can the next engineer change it safely? Look at names, structure, and whether the checks assert behavior at a real entry point.

## Findings

Every finding gives a file and line, the scenario that triggers it, the evidence, the smallest remedy and how to verify the remedy. Check callers and existing safeguards before raising one. When no actionable issue is established, say so in that file and name what was and was not examined.

Severity follows cost, not taste.

- **blocking** is for a concrete cost in one of five classes. The finding names its class in `class:` and the cost in `failure:` (the input or state, and the wrong result it leads to). The gate's `quality findings classed` check fails a blocking finding without both.

| Class | Blocking when |
| --- | --- |
| `duplication` | the same rule now lives in two places that must change together, and you can name the edit that would make them disagree |
| `performance` | the cost is on a path the feature exercises and you can say how it grows: a query per row, an unbounded load, work repeated per request |
| `simpler_design` | a simpler design meets every requirement, and the extra structure has a cost you can name: a caller that must now know more, a state that can no longer be checked |
| `unmet_need` | the specification states a need the solution does not meet |
| `reliability` | a concurrent request, a retry or a failure part-way through leaves wrong data or a lost or repeated side effect |

- **major** is a real cost that does not reach one of those bars. It carries `failure:` and is reported; it does not block.
- **minor** is everything else: a name, a comment, a preference. A finding that cannot name a failure is minor at most.

A reviewer will always find something. Do not raise defensive additions (extra validation, rescues or nil checks for states the code cannot reach), and do not block on style.

## Handoff

- With one or more blocking findings: list their IDs under `blocking`, set `status: blocked` and `next: remediate`. The change goes to remediation (`on_blocking_findings` in `.ai/workflow.yml`), the round counts toward `remediation.max_rounds`, and after remediation the change returns to verification and then to this phase.
- With none: `status: complete`. Major and minor findings stay in `findings` for review and judgment.
- Write `consolidated.md` last. It states the commit reviewed, what the change must keep true, a summary per question, the blocking findings, the findings carried forward and the coverage limits.

Prefer to run on a different provider from the one that implemented or remediated the change (`prefer_different_provider_from` in `skill.yml`). `soft-foundry phase run quality` chooses one when `--shell` is not given.

## Where this phase is asked for

The phase is optional unless the repository's profile turns it on (`quality_gate.enabled` in `.ai/repository.yml`). Where it is on, it is required at medium and high risk on the gated and iterative tracks, stepped over by default at low risk, and optional on the light track. A change may always ask for it by naming `quality` under `run_phases` in its `metadata.yml`. When the diff holds no application code, complete the phase with a statement of what was examined.
