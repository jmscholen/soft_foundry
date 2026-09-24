# Learning

## What this change taught us
Two lessons, recorded as instincts in `instincts.yml`: read the host's contract before writing an adapter (Codex needed a patch parser, not a field rename), and say "policy only" at launch when a host has no hook mechanism (Grok).

## Reviewer/evaluator/attack findings worth generalizing
- REV-010 / REV-018: a committed hook can be inert (Codex's trust step); tooling should say "written" rather than "installed" when it cannot see the host's trust state.
- REV-003: contracts verified from documentation deserve one live run before they are relied on.

## Proposed deterministic checks
- Warn on an apply_patch with no recognised header (REV-001).

## Proposed rule changes
See `proposed-rules.md`.

## Proposed harness evals
See `proposed-evals.md`.
