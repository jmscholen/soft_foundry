# Change Intake

## User intent
Make `soft-foundry init` install the Soft Foundry control plane into an existing Git repository safely and idempotently, so any application repository can adopt the lifecycle without hand-copying files.

## Desired outcome
- The installable control-plane files (`.ai/`, `AGENTS.md` bootstrap, `changes/` scaffolding, `docs/user/` scaffolding where appropriate) ship inside the gem.
- `soft-foundry init` detects the target repository root and refuses non-repository targets unless explicitly supported.
- The canonical `.ai/` control plane is installed into the target repository.
- `AGENTS.md` is installed or safely updated without destroying repository-specific instructions.
- Existing `CLAUDE.md` content is preserved; only a Soft Foundry pointer is added when missing.
- `.soft-foundry/` is gitignored.
- All existing application files are preserved.
- Repeated runs are idempotent: no duplicated content, no unexpected rewrites of unchanged files.
- Every touched file is reported as created, updated, skipped, or conflicting.
- Conflicting user-owned files are never overwritten without an explicit conflict strategy.
- Provider discovery for OpenAI, Anthropic, and xAI/Grok keeps working.

## Constraints
- `AGENTS.md` and `.ai/` in this repository are the canonical source of truth for what gets installed.
- Do not blindly create provider-specific infrastructure in the target repository.
- Do not weaken existing Soft Foundry policies or lifecycle semantics to simplify the implementation.
- Work lands through a pull request on branch `change/init-command`, not by pushing to `main`.
- The pull request must include implementation, automated tests, updated usage documentation, internal documentation, design decisions, tradeoffs, and known limitations.

## Non-goals
- Autonomous skill execution.
- The full `soft-foundry change` workflow beyond what initialization strictly requires. The record and gate commands already exist and are out of scope here.
- Migrating existing target-repository conventions.

## Task classification
feature, application surface only. Touches the gem packaging, CLI, onboarding, and agent-file adapters.

## Initial risk
medium. The command writes into user-owned repositories, so the dominant risk is destroying or duplicating user content. Mitigated by the idempotency, conflict-reporting, and preservation requirements above and by the required test matrix in `assumptions.md`.
