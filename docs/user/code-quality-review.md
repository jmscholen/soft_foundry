# The code-quality review

The code-quality review is a phase in which a reviewer acting as a staff software engineer reads the change's code. It runs after verification and before evaluation, in a fresh session. It writes findings to `changes/<slug>/06a-code-quality/` and does not edit code.

It is an optional gate. A repository turns it on, and then it is required for medium and high risk changes.

## Turn it on or off for a repository

The setting is in `.ai/repository.yml`:

```yaml
quality_gate:
  enabled: true
  set_by: your name
```

- When the setting is absent or `enabled` is false, no change is asked for the phase.
- `soft-foundry init` and `soft-foundry onboard` set `enabled: true` when they detect Ruby, Python, JavaScript, TypeScript or PHP, and false otherwise. They record that in `set_by`.
- A value you set yourself is kept. Onboarding only replaces a value it wrote, so put your name, or anything other than the scan's own text, in `set_by`.

## When a change is asked for it

With the gate on:

| Track | Low risk | Medium risk | High risk |
| --- | --- | --- | --- |
| gated | stepped over by default | required | required |
| iterative | stepped over by default | required | not available (high risk is gated) |
| light | optional | optional | not available (high risk is gated) |

A change record created before the phase existed is never asked for it, whatever the setting.

`soft-foundry change status` shows the phase between verification and evaluation. When it may stay pending, the line gives the reason in words, for example:

```text
  06-verification        complete     ok
  06a-code-quality       pending      the quality gate is off in .ai/repository.yml
  07-evaluation          pending
```

## Run it on request

To run the phase for one change where it is not required, name it in the change's `metadata.yml`:

```yaml
run_phases:
  - quality
```

Then run it in a fresh session:

```bash
soft-foundry phase run quality
```

## What the reviewer answers

1. Does the solution meet the need the specification states, without building more than was asked?
2. Is it the simplest design that meets the specification, and does it fit the conventions of the code around it?
3. Does it repeat logic that already exists in the repository or within the change?
4. Is there a performance or resource problem on a path the feature exercises?
5. Does it stay correct under concurrent requests, retries and a failure part-way through?
6. Can the next engineer change it safely?

Each answer is a file in the phase directory. Each finding gives a file and line, the scenario that triggers it, the evidence, the smallest remedy and how to verify the remedy. `consolidated.md` summarizes them and says what was not examined.

Framework-specific guidance comes from the rule files your repository uses. For a Rails application, `.ai/rules/rails.md` lists the review decisions for associations and data modeling, object design, performance and reliability.

## What can block a change

A finding blocks only when it names a concrete cost in one of five classes.

| Class | It blocks when |
| --- | --- |
| `duplication` | the same rule lives in two places that must change together |
| `performance` | there is a cost on a path the feature exercises, and the finding says how it grows |
| `simpler_design` | a simpler design meets every requirement, and the extra structure has a cost the finding names |
| `unmet_need` | the specification states a need the solution does not meet |
| `reliability` | a concurrent request, a retry or a failure part-way through leaves wrong data or a lost or repeated side effect |

The gate's `quality findings classed` check enforces the form: a blocking finding without a class from that list, or without a `failure:` that states the cost, fails the gate. The check does not judge whether the cost is real. That is the reviewer's claim, and you can read it.

Findings that do not reach that bar are recorded as major or minor. They do not block. Review and judgment read them, and you see them when you accept the result.

## What happens when it blocks

1. The phase is marked blocked and names the blocking findings.
2. The change goes to remediation. The remediation skill has the steps for repairing a quality finding: define the contract, write a behavioral check before the edit, make the smallest coherent edit, run the same checks again.
3. The round counts toward the remediation cap (two rounds by default). Past the cap, the change waits for your decision.
4. After remediation, verification and the code-quality review run again on the new code.

## Limits

- The review is a reader's judgment. It runs no benchmark and no duplication detector of its own; it may use tools your repository already has.
- A change that ran no code-quality review has no code-quality evidence. Judgment records the phase as not run. It is not a pass.
- The setting is a line in `.ai/repository.yml`. Someone with write access to the repository can change it. That is outside what the gate checks.
