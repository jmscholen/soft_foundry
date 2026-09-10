# Assumptions

## Explicit assumptions
- "Budget" means a declared cap plus a recorded ledger and a status check, not automatic enforcement mid-API-call, given no code path makes real completion calls today.
- OpenRouter's default Bearer-token auth matches the existing `Provider` base class; no header override needed, unlike Anthropic's `x-api-key`.
- Given this feature's low risk profile (additive CLI commands and data files, no writes into arbitrary target-repo paths beyond existing `change new` scaffolding) and the maintainer's explicit cost-consciousness in this same conversation, the full sixteen-phase lifecycle with fresh-context agents per phase is disproportionate. This change is implemented and tested directly, with a lighter-weight process than `init-command` received, and that choice is recorded here rather than silently taken.

## Ambiguities resolved
- Whether budget caps should block `soft-foundry ci`/gates: no. Budget status is a separate, informational command; folding it into the gate/predecessor machinery would touch `lib/soft_foundry/gate.rb` and risk the same evidence-invalidation cascade that made `init-command` expensive, for a check that isn't about phase completion.

## Ambiguities that block safe progress
None.
