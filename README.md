# Soft Foundry

Soft Foundry is a repository-native control plane for autonomous software engineering. The repository contains the engineering constitution; the CLI provides onboarding, runtime discovery, agent adapters, and eventually enforced lifecycle orchestration.

## Agent: next implementation milestone

The next milestone is tracked as the change record `changes/init-command/`. Its intake phase is complete; the next phase is `discover`. If you are an engineering agent asked to continue implementing Soft Foundry, read `AGENTS.md`, `.ai/README.md`, and `.ai/workflow.yml`, then:

```bash
git checkout -b change/init-command
soft-foundry change status init-command
```

Work the phases in lifecycle order, complete each phase's handoff, and run `soft-foundry gate <phase>` before moving on. The quality of that pull request is also an evaluation of Soft Foundry itself: if repository instructions are ambiguous, contradictory, incomplete, or prevent safe implementation, document those problems in the change record rather than silently inventing new workflow semantics.

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

## Change records and gates

Every change gets a durable record under `changes/<slug>/`, scaffolded from the phase templates:

```bash
git checkout -b change/<slug>
soft-foundry change new <slug> --title "..."
soft-foundry change status            # phase-by-phase status for the current branch
soft-foundry gate verify              # evaluate one phase's completion gate
soft-foundry gate all --change <slug>
```

A gate passes only when the phase's required files exist with no `TBD` placeholders, the handoff is valid, nothing is blocking, the predecessor phase is complete, and commit-bound evidence is not stale. Evidence is stale when any file in the `APP`, `TESTS`, or `INFRA` path groups changed after the recorded commit. See `.ai/schemas.md`.

`soft-foundry check` lints the control plane itself. `soft-foundry ci` runs the lint plus every change record's gates, and `soft-foundry hooks install` wires it into a pre-commit hook. The GitHub Actions workflow runs the same two commands.

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

- `.ai/` — how engineering is performed: workflow, skills, rules, policies, profiles, path groups, templates, gates.
- `AGENTS.md` — universal bootstrap for coding agents.
- `CLAUDE.md` and future vendor files — thin compatibility pointers only.
- `.soft-foundry/` — local provider/model runtime state; never committed.
- `changes/` — durable per-change provenance and evidence.
- `infra/` — application operational definition.
- `docs/` — canonical product/user documentation.

A skill requests a capability profile such as `coding_high`; provider/model selection is a runtime concern. OpenAI, Anthropic, xAI/Grok, local models, and future providers should be interchangeable where they satisfy the skill contract.