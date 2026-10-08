# Change Intake

## User intent
Change 2 of the shared plan ("Soft Foundry: Agent-Workflow Additions Plan"), which the maintainer asked to build in order and said "lets move to #2" once change 1 (#42, #43) had merged. From the article it adapts: "when you've finished work, spin up a Fable agent and ask for a code review, and fix anything that doesn't result in needlessly defensive slop", because a reviewer "will *always* find 20 things, most of which are bloat."

Today `phase run` uses Claude Code unless `--shell` says otherwise, so a review of Claude-implemented work runs on the same provider by default; the judgment profile asks only for a different execution context. Change 1 showed the value of the other path: its review and judgment ran on Grok through `phase run --shell grok` and found REV-SEC-001, which the implementing session's own threat model had missed.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-XP-001 (policy).** The review and final-judgment skills declare `prefer_different_provider_from: [implement, remediate]` in `skill.yml`. `soft-foundry check` fails a skill whose list names something that is not a lifecycle phase.
- **REQ-XP-002 (provider of a phase).** The provider a completed phase ran on is read from its handoff: `resolved_model.provider` (case-insensitive; `anthropic`, `openai`, `xai`, with `claude`, `codex`, `grok`, and `x.ai` accepted as the same), else `executed_by.shell` mapped the same way, else unknown.
- **REQ-XP-003 (runner default).** `phase run <phase>` with no `--shell`, for a phase whose skill declares the preference, picks the first installed shell, in the order claude, codex, grok, whose provider differs from every known provider of the named phases, and prints the choice and the reason as one `shell:` line. If no installed shell differs, it uses the first installed shell and prints a `! warn shell:` line saying why. With `--shell`, the person's choice stands. Phases whose skill declares no preference behave as today.
- **REQ-XP-004 (advisory).** A completed review or judgment whose provider equals the provider of one of the phases its skill names gets a go-live advisory naming both. Like every advisory, it never fails the gate.
- **REQ-XP-005 (finding format).** Every finding in the review handoff with severity `blocking` or `major` carries a non-empty `failure:` (the concrete input or state and the wrong result it leads to). The gate's new `findings explained` check on the review phase fails when one does not. The review templates' finding tables gain a "Failure it prevents" column, and the handoff template documents the field.
- **REQ-XP-006 (review rule).** The review skill says a finding with no concrete failure is minor at most, and that defensive additions (extra validation, rescues, nil checks for states the code cannot reach) are not blocking or major unless the reviewer names the input that reaches them.
- **REQ-XP-007 (docs).** README, help text, and `.ai/schemas.md` describe the preference, the runner default, the advisory, and the `failure:` field and check. Version 0.19.0.

## Constraints
- The gate stays a structure check: it confirms `failure:` is present and non-empty, not that the failure is real.
- No existing record is reopened; closed records are not gated by `ci`.
- `--shell` always wins over the default.
- Every new output line carries a status word (`.ai/rules/accessibility.md`).

## Non-goals
- Checking that a shell is logged in before choosing it (a shell that fails to start exits non-zero and the runner reports it, as today). Codex's login on this machine has expired and the maintainer has paused Codex testing; the runner's default may therefore choose Codex here, and `--shell grok` is the way round it.
- Panels of several reviewers (change 3).
- A machine-local shell preference order.

## Task classification
Feature: a skill.yml key and its lint, provider resolution, a runner default, an advisory, a gate check, template and skill text, documentation, tests.

## Initial risk
low. The runner's default changes only for review and judgment and only when `--shell` is absent; the new gate check applies only to blocking and major review findings in open records.
