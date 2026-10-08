# Learning

## What this change taught us
- **Name the exception, not the vocabulary.** The first `findings explained` listed the severities that need a failure (`blocking`, `major`); the attack phase got a serious finding past it by calling it `critical`. Listing the one severity that may go without (`minor`) closed it (FIND-ATK-001, REM-001).
- **Partial knowledge is still knowledge.** The runner gave up on choosing a provider as soon as one named phase's provider was unknown, and so could pick the implementer's own provider (REV-FUN-001, REM-002). The second review, after the fix, found nothing.
- **The feature reviewed itself.** Change 2's review and judgment ran on Grok through `phase run`; the first review found a major defect in the very code that picks the reviewer, which the implementing (Anthropic) session's own evaluation had not covered.
- **A default that picks a logged-out shell fails loudly.** On this machine the default for Claude-implemented work is Codex, whose login has expired; the intake made "installed, not logged in" a non-goal, and `--shell grok` was used. A later change could check login state where a shell exposes it.

## Reviewer/evaluator/attack findings worth generalizing
- FIND-ATK-001: any gate check that keys on a free-text field must treat unexpected values as the strict case.
- REV-FUN-001: when combining several inputs, an unknown one must not discard the known ones.

## Proposed deterministic checks
- None beyond what this change added.

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
