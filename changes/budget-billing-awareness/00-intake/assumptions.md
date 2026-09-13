# Assumptions

## Explicit assumptions
- "Subscription" means the coding shell is logged in to a plan and no metered credential is present in the environment. Detection is a heuristic over variable presence: `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX` for `claude`; `OPENAI_API_KEY` for `codex`; `XAI_API_KEY` for `grok`; any of the four provider keys for a generic command. Settings-file mechanisms (Claude Code's `apiKeyHelper`, for instance) are not inspected; `SOFT_FOUNDRY_BILLING` exists precisely so a user whose setup the heuristic misreads can correct it in one line.
- "Periodic warning every $10" means every $10 of *recorded* spend on the change, evaluated when an entry is recorded, because the ledger is the only thing this tool can see move. Multiple boundaries crossed by one large entry produce one warning naming the highest boundary crossed.
- The warning interval is a per-machine preference (stored gitignored in `.soft-foundry/budget.yml`), while the cap and the human-approval line stay repository policy. `off` silences only the interval; the approval line and the cap still speak.
- Given this feature's low risk profile and the maintainer's established cost-consciousness, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly under the lighter-weight process used by `budget-and-openrouter`, `self-update`, `maturity-report`, and `change-close-command`, and that choice is recorded here rather than silently taken.

## Ambiguities resolved
- Whether a subscription should suppress `budget record` entirely: no. Recording is data and harmless; only the budget-shaped consequences (warnings, cap, non-zero exit) are suppressed.
- Whether `budget record` should exit non-zero when it pushes the change over cap: yes (exit 2, after writing the entry). The policy's `on_exceed: stop_and_escalate` needs a signal an agent cannot miss, and the entry is still written so the ledger stays truthful.
- Whether to print the notice before or after `init` installs the control plane: after, so the cap and interval can be read from the freshly installed policy; before the deep maturity assessment, since that is the moment `init`/`onboard` spends.

## Ambiguities that block safe progress
None.
