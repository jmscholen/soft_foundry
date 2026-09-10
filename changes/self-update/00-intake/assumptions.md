# Assumptions

## Explicit assumptions
- "Confirm before touching anything" is satisfied by requiring a second, explicit `--yes` invocation, matching how `--force` and `--dry-run` already work in this CLI, rather than an interactive prompt.
- Given this change's scope and the established pattern for small CLI additions to this repository, it receives the same lighter-weight process as budget-and-openrouter and maturity-onboarding: implemented and tested directly, with real verification, rather than a fresh-context agent per lifecycle phase.

## Ambiguities resolved
- Whether `update` should check on every command invocation: no, explicitly a non-goal. An update check is a deliberate, operator-initiated action, not an automatic background one.

## Ambiguities that block safe progress
None.
