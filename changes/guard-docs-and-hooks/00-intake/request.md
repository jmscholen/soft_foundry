# Change Intake

## User intent
The owner asked for the status of the factory-readiness session against `main`, was told that two of that record's conditions of approval were still open on `main`, and said: "Ok. Do it."

The two conditions, from `changes/factory-readiness/14-judgment/final.md` and PR #49:

1. The guard's documentation was never brought up to date: the README guard section, the header of `.ai/policies/enforcement.yml`, and the live-eval note (REV-001, REV-010, EVAL-F1, EVAL-F5 in that record).
2. This repository's own hook settings still carry the old matcher (no Grep or Glob) and no PostToolUse entry, so the post-call restore that 0.21.0 ships is not active here until `soft-foundry hooks install --claude` is rerun.

## Desired outcome
- **REQ-GDH-001.** `.claude/settings.json` carries the PreToolUse matcher `Edit|Write|MultiEdit|NotebookEdit|Read|Grep|Glob|Bash` and the PostToolUse `guard --after` entry; `.codex/hooks.json` is the current install. Applied by the maintainer commit `b9f4d7c`, because no skill may write the guard's own configuration.
- **REQ-GDH-002.** The header of `.ai/policies/enforcement.yml` describes the guard as it behaves on `main`: what each tool is checked against, how a shell command is read, that a command may name what the skill may read, that an undecidable call is refused, what the guard's own configuration is, the post-call restore, and what can still get past it. Applied by `b9f4d7c` (protected policy).
- **REQ-GDH-003.** `.ai/harness-evals/README.md` says an unattended Claude Code live eval needs shell arguments to write the phase directory, with the invocation. Applied by `b9f4d7c` (harness material).
- **REQ-GDH-004.** `README.md` says the same things where a person reads them: the guard section (Grep and Glob, how a shell command is read, fail closed, the guard's own configuration including `.soft-foundry/`, the post-call restore and its limits, rerunning `hooks install --claude` on an existing repository, `soft-foundry guard --after` once after an interrupted shell command before editing the configuration by hand) and the harness-evals section (the live-eval shell arguments). Written in this record's documentation phase, which may write `README.md` since #61.
- **REQ-GDH-005.** Nothing else changes: no application, test, or infrastructure code. The suite, `check`, `eval`, and `ci` pass as on `main`.

## Constraints
- The text describes `main` as it is (0.23.0), not as factory-readiness left it; gate-hardening and later changes are read first.
- Every claim in the new text is one a reader can check against the code or a command's output.
- `.ai/rules/accessibility.md` applies to the README (a document a person reads).

## Non-goals
- `doctor` reporting a missing PostToolUse entry or an old matcher (factory-readiness REV-001, proposed check). That is a code change for a later record.
- Closing any residual factory-readiness accepted (same-user routes, root-wide reads).
- A version bump.

## Task classification
Docs: documentation and one hook reinstall, no code.

## Initial risk
low. Text and a hook settings file; the hook entries are what `hooks install` writes in every repository.
