# Learning

## What this change taught us
- The gate and advisory were already structured; the missing piece was one place that decides what leaves the process. Adding it was small because computation and printing were only tangled in the CLI's own helpers.
- Three RED tests encoded guesses about existing behaviour (branch-relative staleness, YAML refusing invalid UTF-8, a per-risk budget cap). Reading the method under test before asserting on it would have avoided each.
- Running `main`'s code and the branch's code against the same real records, and diffing, is a cheap and complete regression check for a refactor of printing code.
- Real records hold inconsistent clocks: agent-typed handoff times and tool-written `created_at` disagree by hours.

## Reviewer/evaluator/attack findings worth generalizing
- REV-011: a data layer that repeats record text makes every consumer responsible for treating it as text.
- EVAL-NOTE-002: times typed by an agent should be written by the tool.

## Proposed deterministic checks
- Compare `Gate.checks_for` with what `Gate#evaluate` runs for every phase of a fully completed fixture record.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
