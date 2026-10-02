# Soft Foundry

Soft Foundry is a control plane you commit next to the code. Agents follow a
declared lifecycle; the CLI checks that they actually did.

It is for teams that want coding agents constrained by the repository — not
by whatever happened to be in the current chat. Spec-driven toolkits such as
GitHub Spec Kit guide an agent through specify → plan → implement. Soft
Foundry's bet is different: **evidence is stale if the code moved,
permissions are data, and judgment is a separate process boundary.**

A five-minute picture of the intended loop is in [`examples/tiny-app/`](examples/tiny-app).

## 60-second start

```bash
gem install soft_foundry          # once it is published; until then, see Install
cd your-app
soft-foundry init                 # writes .ai/ and AGENTS.md, then onboard
git checkout -b change/add-json-flag
soft-foundry change new add-json-flag --title "Add a --json flag"
soft-foundry change status
soft-foundry doctor
```

`init` into an application repository packages the **iterative** track as
the default: explore with a person, `change vet` when they accept, then
harden. `high` risk still forces the **gated** track. This repository
itself stays gated.

## Install

Until the gem is on RubyGems (`soft-foundry update` will say so):

```bash
git clone https://github.com/jmscholen/soft_foundry.git
cd soft_foundry
gem build soft_foundry.gemspec
gem install ./soft_foundry-0.15.0.gem
```

Requires Ruby 3.2+. During development of Soft Foundry itself:

```bash
bundle exec ruby -Ilib exe/soft-foundry version
```

## What you get

| Piece | Role |
| --- | --- |
| `AGENTS.md` | Vendor-neutral entry point. `CLAUDE.md` only points here. |
| `.ai/` | Lifecycle, skills, permissions, rules, maturity policy. |
| `changes/<slug>/` | Durable record of one change: phases, evidence, judgment. |
| `soft-foundry gate` | A phase passes only with required files, no `TBD`, a valid handoff, a live predecessor, and non-stale commit-bound evidence. |
| `soft-foundry guard` | PreToolUse hook for Claude Code and Codex. Default mode is `warn`. |
| `.soft-foundry/` | Machine-local runtime and enforcement overrides. Gitignored. Credentials never land in the repo. |

## Onboard a repository

```bash
soft-foundry onboard
```

Onboarding keeps `AGENTS.md` as the canonical entry point, creates or
augments `CLAUDE.md` with only a pointer, and discovers configured model
providers.

Provider credentials are detected from the environment:

- OpenAI: `OPENAI_API_KEY`
- Anthropic: `ANTHROPIC_API_KEY`
- xAI / Grok: `XAI_API_KEY`
- OpenRouter: `OPENROUTER_API_KEY` — one key proxying many providers through an OpenAI-compatible endpoint

The accessible model inventory is written to `.soft-foundry/runtime.yml`.

## Maturity assessment

`init`/`onboard` evaluate the repository against `.ai/maturity.yml` and
write `.ai/repository.yml`, once. A repository already assessed
(`repository.assessed: true`) is skipped later; pass `--reassess` to force
a fresh run.

```bash
soft-foundry init --maturity=scan     # default: free, deterministic, offline
soft-foundry init --maturity=deep     # shells into `claude` for real judgment; costs tokens
soft-foundry init --maturity=off      # skip entirely
soft-foundry onboard --maturity=scan --reassess
```

`scan` detects languages, frameworks, testing, and infrastructure from
file presence and scores only what file presence can honestly answer —
roughly levels 1 and 2. Everything else stays `UNKNOWN`, never guessed.
Levels 3+ need proof that changes went through the lifecycle.

`deep` shells into an installed `claude` CLI. It is best-effort and never
blocks the rest of `init`/`onboard`.

Every assessment prints a summary and writes `.ai/maturity-report.md`.
The report regenerates only when the underlying assessment changes.

```bash
soft-foundry models
soft-foundry doctor
```

## Change records and gates

```bash
git checkout -b change/<slug>
soft-foundry change new <slug> --title "..."
soft-foundry change status            # phase-by-phase status for the current branch
soft-foundry gate verify              # evaluate one phase's completion gate
soft-foundry gate all --change <slug>
```

A gate passes only when the phase's required files exist with no `TBD`
placeholders, the handoff is valid, nothing is blocking, the predecessor
phase is complete, and commit-bound evidence is not stale. Evidence is
stale when any file in the `APP`, `TESTS`, or `INFRA` path groups changed
after the recorded commit, measured on the record's own branch while that
branch exists. See `.ai/schemas.md`.

`soft-foundry check` lints the control plane itself. `soft-foundry ci`
runs the lint plus every change record's gates. `soft-foundry hooks install`
wires that into a pre-commit hook. The GitHub Actions workflow runs the
same two commands.

### Runtime enforcement: the guard hook

Every skill's `permissions.yml` declares what it may read and write.
`soft-foundry guard` is a host-neutral PreToolUse hook: JSON on stdin,
exit 2 to refuse.

```bash
soft-foundry hooks install --claude            # .claude/settings.json
soft-foundry hooks install --claude --local    # .claude/settings.local.json
soft-foundry hooks install --codex             # .codex/hooks.json; then /hooks inside Codex
soft-foundry hooks uninstall --claude
soft-foundry doctor                            # hosts, hook presence, mode
```

| Surface | Enforced? |
| --- | --- |
| Edit / Write / MultiEdit / NotebookEdit / Codex `apply_patch` vs write and deny_write | Yes |
| Read vs deny_read | Yes |
| Bash vs deny sets, only when the command text names a denied path | Partial |
| What a Bash command actually writes | No — policy only |
| Grok | No — no hook mechanism; `phase run --shell grok` says so |
| Anything outside a live change branch | No |

Mode comes from `.ai/policies/enforcement.yml` (`warn` by default), then
`.soft-foundry/enforcement.yml`, then `SOFT_FOUNDRY_GUARD=warn|block|off`.
See [SECURITY.md](SECURITY.md).

### Scanning the control plane as an attack surface

`.ai/`, `AGENTS.md`, `CLAUDE.md`, and every change record are inputs an
agent reads. `soft-foundry check` and the gate's `content clean` check
scan them:

| Kind | What it is | Level |
| --- | --- | --- |
| `invisible` | zero-width, bidirectional, and tag characters | error everywhere |
| `secret` | AWS, OpenAI-style, GitHub, Slack, and Google key shapes, private key blocks | error everywhere |
| `override` | "ignore previous instructions", "you are now", "hide this from the user" | error under `.ai/policies/`, warning elsewhere |
| `fetch_exec` | `curl ... \| sh`, download-and-invoke | error under `.ai/policies/`, warning elsewhere |

A quoted attack may add `soft-foundry:scan-allow` on that line. Closed
evidence is exempted by `.ai/policies/content-scan.yml`, never by editing
the evidence. Invisible text is never exempt.

```bash
soft-foundry scan [paths...]
```

### Instincts

The learning phase writes `15-learning/instincts.yml`. Promotion copies
high-confidence instincts into `.ai/rules/learned.md` through a later
change's record, never by the change that learned them.

```bash
soft-foundry learn list
soft-foundry learn list --min-confidence 0.9
soft-foundry learn promote
soft-foundry learn promote --dry-run
```

### RED and GREEN evidence

Verification can bind a failing-test-first claim to git. A check in
`06-verification/tests.yml` names `red_commit` and `test_path`. The
verification gate checks that the commit exists, precedes the verified
commit, holds the test file, and that `APP` or `INFRA` changed after it.
It does not re-run the test at the RED commit.

### Fresh-context phases: `phase run`

Review and judgment exist to look at the work from outside it.

```bash
soft-foundry phase run review
soft-foundry phase run judge --shell codex
soft-foundry phase run judge --shell grok
soft-foundry phase run review --dry-run
soft-foundry phase run review -- --model opus
```

The runner refuses what the gate would refuse afterwards, stamps
`executed_by` on the handoff, and gates the phase when the session
returns. A completed review or judgment with no `executed_by` draws an
advisory: separation of duties then rests on the handoff's notes. In
guard `block` mode, treat that advisory as a reason not to ship.

### Lifecycle tracks: gated or iterative

- **`gated`** — every phase in order; specification locks when it completes. Default in *this* repository.
- **`iterative`** — exploring stage first, deploy only to the development environment in `.ai/repository.yml`, journal rounds in `exploration/iterations.yml`. `change vet` is the person's acceptance; then implement-onward applies as on gated. Packaged default for `soft-foundry init` targets.

```bash
soft-foundry change new <slug> --track iterative
soft-foundry change vet <slug>
soft-foundry gate implement
soft-foundry change reopen <slug> --reason "..."
```

`high` risk is always gated (`tracks.forced_by_risk`).

### Closing a change record

```bash
soft-foundry change close <slug>
soft-foundry change close <slug> --force
soft-foundry change request-discharge <slug> --pr <N>
soft-foundry change close <slug> --pr <N>
soft-foundry change close <slug> --confirm AC-060 --confirm AC-061
```

An un-closed record that has reached judgment stays live to the gate
checker: a later edit to a covered path group will read as stale evidence.

### Go-live advisories

Advisories print after `gate`, `change status`, `ci`, and `change close`.
They never change the exit code. They cover skipped review/judgment,
missing fresh-context `phase run`, accessibility, policy conformance, and
missing RED evidence.

## Updating

```bash
soft-foundry update          # checks RubyGems; writes nothing
soft-foundry update --yes    # installs if a newer version exists
```

No interactive prompts. The gem is not on RubyGems yet; `update` reports
that rather than failing silently.

## Budget

`.ai/policies/budget.yml` declares spend limits. Whether they apply
depends on how the machine pays for models:

- **Subscription** (Claude Code / Codex logged-in plan): no budget applies.
- **API key** in the environment: the budget policy applies.

This is a ledger, not live metering. Record spend with
`soft-foundry budget record`. `SOFT_FOUNDRY_BILLING=api` or
`subscription` overrides detection.

## Coding shells

```bash
soft-foundry shell claude
soft-foundry shell codex
soft-foundry shell grok
```

`grok` launching needs a `grok` executable on `PATH`. xAI model discovery
works without it.

## Adversarial testing and authorization

The ATTACK phase is authorized adversarial engineering against the
application under development. Local, ephemeral, or staging environments
with synthetic data are preferred. Production, destructive actions,
third-party systems, and real customer data require explicit authorization
under `.ai/policies/human-boundaries.yml`.

The harness determines **what is authorized**; the adversarial model
determines **how to challenge the system within that authorization**.
Provider fallback must not circumvent a safety or authorization refusal.

## Architecture

- `.ai/` — how engineering is performed
- `AGENTS.md` — universal bootstrap
- `CLAUDE.md` — thin pointer only
- `.soft-foundry/` — local runtime; never committed
- `changes/` — provenance for *this* repository's own history
- `examples/tiny-app/` — the loop an adopter should learn first
- `docs/contributing.md` — how to work on Soft Foundry itself
- `docs/user/` — product-facing knowledge, once evaluation journeys exist

A skill requests a capability profile such as `coding_high`; provider
selection is a runtime concern.

## License

MIT. See [LICENSE](LICENSE). Vulnerability reports: [SECURITY.md](SECURITY.md).
