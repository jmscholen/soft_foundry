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
- OpenRouter: `OPENROUTER_API_KEY` — a single key proxying many providers' models through one OpenAI-compatible endpoint, often at lower cost than a provider's own API

The accessible model inventory is written to `.soft-foundry/runtime.yml`, which is machine-local and must remain gitignored. Credentials are never written to repository configuration.

## Maturity assessment

`init`/`onboard` evaluate the repository's engineering maturity against `.ai/maturity.yml` and write the result to `.ai/repository.yml`, once. A repository already assessed (`repository.assessed: true`) is skipped on later runs; pass `--reassess` to force a fresh assessment.

```bash
soft-foundry init --maturity=scan     # default: free, deterministic, offline
soft-foundry init --maturity=deep     # shells into `claude` for real judgment; costs tokens/subscription usage
soft-foundry init --maturity=off      # skip entirely
soft-foundry onboard --maturity=scan --reassess
```

`scan` detects languages, frameworks, testing, and infrastructure from file presence alone (a `Gemfile` with `rails`, a `package.json` dependency, `*.tf` files, and so on) and scores only the maturity capabilities file presence can honestly answer — roughly levels 1 and 2. Everything it cannot determine is left `UNKNOWN`, never guessed, per `.ai/maturity.yml`'s own assessment rules. Levels 3 and above (specs, verification, adversarial testing, judgment gates) require proof that changes actually went through the lifecycle; no scan of an unstarted repository can manufacture that.

`deep` shells into an installed `claude` CLI to run the real `repository-discovery` skill with actual judgment, reaching whatever level the repository has genuinely earned. It is best-effort: exact non-interactive behavior can vary by installed Claude Code version, so a failure is reported plainly rather than silently ignored, and it never blocks the rest of `init`/`onboard` from completing.

Every assessment — a fresh scan, a fresh deep run, or just showing an already-assessed repository's existing result — prints a summary (current level, what's blocking the next one, a count of other recorded deficiencies) and writes `.ai/maturity-report.md`: a persisted, human-readable rendering of the same capability findings that live in `.ai/repository.yml`, grouped into what blocks the next level versus everything else recorded. It regenerates only when the underlying assessment actually changes, so a repeated run leaves no diff.

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

## Updating

```bash
soft-foundry update          # checks RubyGems, reports current vs. latest; writes nothing
soft-foundry update --yes    # installs the newer version if one was found
```

This tool has no interactive prompts anywhere. `--yes` is the explicit second step that actually installs, the same way `--force` and `--dry-run` work elsewhere in this CLI: the plain command is always safe to run and never touches anything.

## Budget

Model API usage can get expensive, especially across a long-running change with multiple phases. `.ai/policies/budget.yml` declares spend limits (`max_usd_per_change`, overridable by a change's declared `risk` level) and a threshold above which continuing is a financial commitment requiring human approval, per `.ai/policies/human-boundaries.yml`.

This is policy and a ledger, not live metering: nothing in Soft Foundry today intercepts a real model API call, so nothing can enforce a cap automatically mid-call. Whoever executes a phase — a human or an agent — records what it cost:

```bash
soft-foundry budget record --change <slug> --phase 05-implementation \
  --provider openrouter --model "some/model" \
  --tokens-in 12000 --tokens-out 3000 --usd 0.08
soft-foundry budget status --change <slug>
```

`budget status` sums the ledger, compares it against the policy cap for the change's declared risk, and exits non-zero when the recorded spend is over cap. `--usd` is optional per entry; entries without a cost are counted but excluded from the total, and `budget status` reports how many are missing.

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