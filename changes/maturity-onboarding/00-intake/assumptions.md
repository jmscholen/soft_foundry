# Assumptions

## Explicit assumptions
- "Already assessed" means `.ai/repository.yml`'s `repository.assessed` is `true`, regardless of which mode or command produced it.
- `deep` mode's exact non-interactive invocation (`claude -p "<prompt>"`) is Claude Code's documented headless/print mode; exact behavior can vary by installed version, so failures are reported, not assumed away.
- Given this change's scope and the cost concern that motivated the adjacent budget-and-openrouter change, it receives the same lighter-weight process: implemented and tested directly, with real verification, rather than a fresh-context agent per lifecycle phase.

## Ambiguities resolved
- Whether `--maturity` should default to `scan` or `off`: `scan`, since it is free and gives real value with no cost or opt-in friction; `off` is available for anyone who wants today's behavior.
- Whether `deep` mode should retry or fall back to another provider on failure: no. Per the adversarial-testing skill's own precedent (provider fallback must never be used to route around a boundary), a `deep` failure is reported as-is; the operator decides whether to retry, fall back to `scan`, or investigate.

## Ambiguities that block safe progress
None.
