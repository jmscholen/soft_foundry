# Soft Foundry

Soft Foundry is a repository-native control plane for autonomous software engineering. The repository contains the engineering constitution; the CLI provides onboarding, runtime discovery, agent adapters, and eventually enforced lifecycle orchestration.

## Agent: next implementation milestone

If you are an engineering agent reading this repository because you were asked to continue implementing Soft Foundry, read `AGENTS.md`, `.ai/README.md`, and `.ai/workflow.yml` before changing code. Follow the Soft Foundry lifecycle and implement the work through a pull request rather than pushing directly to `main`.

### Goal

Make `soft-foundry init` install the Soft Foundry control plane into an existing Git repository safely and idempotently.

### Required behavior

- Treat `AGENTS.md` and `.ai/` in this repository as the canonical source of truth.
- Package the installable repository control-plane files with the gem.
- Detect the target repository root and refuse unsafe/non-repository targets unless explicitly supported.
- Install the canonical `.ai/` control plane into the target repository.
- Install or safely update `AGENTS.md` without destroying repository-specific instructions.
- Create `changes/` scaffolding.
- Create user-documentation scaffolding only where appropriate.
- Ensure `.soft-foundry/` is gitignored.
- Preserve all existing application files.
- Preserve existing `CLAUDE.md` content and add only a Soft Foundry pointer when one is missing.
- Be idempotent: repeated `soft-foundry init` runs must not duplicate content or unexpectedly rewrite unchanged files.
- Report files as created, updated, skipped, or conflicting.
- Do not blindly create provider-specific infrastructure.
- Do not overwrite conflicting user-owned files without an explicit conflict strategy.
- Keep provider discovery for OpenAI, Anthropic, and xAI/Grok intact.

### Required tests

Cover at minimum:

- installation into a clean Git repository
- an existing `AGENTS.md`
- an existing `CLAUDE.md`
- repeated initialization
- conflicting `.ai/` content
- `.gitignore` behavior
- preservation of unrelated application files

### Scope boundaries

Do **not** implement autonomous skill execution in this milestone. Do **not** implement the full `soft-foundry change` workflow unless a minimal abstraction is strictly required by initialization. Do not weaken existing Soft Foundry policies or lifecycle semantics to simplify the implementation.

Before coding, inspect the current CLI/gem structure and produce a short implementation plan in the pull request description. The PR must include implementation, automated tests, updated usage documentation, relevant internal documentation, design decisions, tradeoffs, and known limitations.

The quality of this PR is also an evaluation of Soft Foundry itself: if repository instructions are ambiguous, contradictory, incomplete, or prevent safe implementation, document those problems rather than silently inventing new workflow semantics.

## Install from this repository

```bash
gem build soft_foundry.gemspec
gem install ./soft_foundry-0.1.0.gem
```

Or during development:

```bash
bundle exec ruby -Ilib exe/soft-foundry version
```

## Onboard a repository

From an existing application repository:

```bash
soft-foundry onboard
```

Onboarding keeps `AGENTS.md` as the canonical vendor-neutral entry point, creates or augments `CLAUDE.md` with only a pointer to the canonical instructions, and discovers configured model providers.

Provider credentials are detected from the environment:

- OpenAI: `OPENAI_API_KEY`
- Anthropic: `ANTHROPIC_API_KEY`
- xAI / Grok: `XAI_API_KEY`

The accessible model inventory is written to `.soft-foundry/runtime.yml`, which is machine-local and must remain gitignored. Credentials are never written to repository configuration.

```bash
soft-foundry models
soft-foundry doctor
```

## Coding shells

Soft Foundry can launch an installed coding shell from inside the repository:

```bash
soft-foundry shell claude
soft-foundry shell codex
soft-foundry shell grok
```

The launched agent is expected to load the repository's canonical `AGENTS.md` / `.ai/` workflow. `grok` shell launching requires a Grok-compatible CLI executable named `grok` on `PATH`; xAI API model discovery works independently of that shell integration.

## Adversarial testing and authorization

Soft Foundry's ATTACK phase performs authorized adversarial engineering against the application being developed. It is broader than penetration testing: it attempts to break assumptions involving authorization, malformed input, isolation, concurrency, retries, dependencies, resource abuse, reliability, integrity, and security.

Before ATTACK runs, the harness must establish an authorization envelope describing the target environment, allowed and prohibited surfaces, data and network constraints, and whether destructive actions are permitted. Local, ephemeral, test, or staging environments with synthetic data are preferred. Production, destructive actions, third-party systems, real customer data, and credential-sensitive operations require explicit authorization under the human-boundary policy.

Model providers may refuse some adversarial actions. Soft Foundry must not use provider fallback to circumvent a legitimate safety or authorization refusal. A refusal caused by missing authorization or unsafe scope blocks the attack and is recorded. A non-safety runtime limitation, such as missing browser capability or transient provider failure, may be resolved by selecting another model/runtime that satisfies the `adversarial_high` profile while preserving exactly the same authorization envelope.

In short: the harness determines **what is authorized**; the adversarial model determines **how to challenge the system within that authorization**.

## Architecture

- `.ai/` — how engineering is performed: workflow, skills, rules, policies, profiles, gates.
- `AGENTS.md` — universal bootstrap for coding agents.
- `CLAUDE.md` and future vendor files — thin compatibility pointers only.
- `.soft-foundry/` — local provider/model runtime state; never committed.
- `changes/` — durable per-change provenance and evidence.
- `infra/` — application operational definition.
- `docs/` — canonical product/user documentation.

A skill requests a capability profile such as `coding_high`; provider/model selection is a runtime concern. OpenAI, Anthropic, xAI/Grok, local models, and future providers should be interchangeable where they satisfy the skill contract.