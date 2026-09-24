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

A gate passes only when the phase's required files exist with no `TBD` placeholders, the handoff is valid, nothing is blocking, the predecessor phase is complete, and commit-bound evidence is not stale. Evidence is stale when any file in the `APP`, `TESTS`, or `INFRA` path groups changed after the recorded commit, measured on the record's own branch while that branch exists (so a change stacked on another change's branch does not stale the earlier record) and on the worktree otherwise. See `.ai/schemas.md`.

`soft-foundry check` lints the control plane itself. `soft-foundry ci` runs the lint plus every change record's gates, and `soft-foundry hooks install` wires it into a pre-commit hook. The GitHub Actions workflow runs the same two commands.

### Runtime enforcement: the guard hook

Every skill's `permissions.yml` declares what it may read and write, and `check` lints those declarations. `soft-foundry guard` enforces them while a coding shell is running: it is a Claude Code PreToolUse hook that reads each tool call, resolves the active change from the branch and the active skill from the change's status and `current_phase` (the track's stage skill while exploring), expands the skill's sets through the path groups, and decides.

```bash
soft-foundry hooks install --claude            # writes the hook into .claude/settings.json (shared)
soft-foundry hooks install --claude --local    # or .claude/settings.local.json (this machine only)
soft-foundry hooks uninstall --claude          # removes only Soft Foundry's entry
soft-foundry doctor                            # reports whether the hook is installed and the mode in effect
```

The mode is declared in `.ai/policies/enforcement.yml` (`warn` by default: report the violation, let the call through, log it to the machine-local `.soft-foundry/guard.log`; `block`: refuse it; `off`). A machine can override it in `.soft-foundry/enforcement.yml` or with `SOFT_FOUNDRY_GUARD=warn|block|off`, which wins over both. Outside a change branch, or once a change is closed, nothing is guarded.

What is checked: Edit, Write, MultiEdit, and NotebookEdit against the write and deny_write sets; Read against deny_read only; Bash against the deny sets only, because the guard cannot know what a command writes, so it refuses a command that names a denied path and passes everything else. A restriction the guard cannot see is still policy the agent must honor, as `AGENTS.md` says. Every refusal or warning names the tool, the path, the skill, and the mode:

```
✗ fail guard: Edit .ai/rules/ruby.md is in implementation's deny_write set; the implementation skill's permissions.yml does not allow it (mode: block, .ai/policies/enforcement.yml)
```

### Scanning the control plane as an attack surface

`.ai/`, `AGENTS.md`, `CLAUDE.md`, and every change record are inputs an agent reads, and anyone who can open a pull request may have written them. `soft-foundry check` now reads them the way an attacker would want them read, and the gate's `content clean` check does the same for a completed phase's files:

| Kind | What it is | Level |
| --- | --- | --- |
| `invisible` | zero-width, bidirectional, and tag characters a person cannot see | error everywhere, never exempt |
| `secret` | AWS, OpenAI-style, GitHub, Slack, and Google key shapes, private key blocks | error everywhere |
| `override` | "ignore previous instructions", "you are now", "hide this from the user" and the like | error under `.ai/policies/`, warning elsewhere |
| `fetch_exec` | `curl ... \| sh`, `sh -c "$(wget ...)"`, PowerShell download-and-invoke | error under `.ai/policies/`, warning elsewhere |

A rule or threat model that quotes an attack as an example adds `soft-foundry:scan-allow` to that line; a documented example key can do the same. Evidence that cannot be edited (a closed record's logs) is exempted instead by an entry in `.ai/policies/content-scan.yml` naming the paths, optionally the kinds and a substring, and a reason that `check` requires. Invisible text is never exempt. `soft-foundry scan [paths...]` runs the same scan over the control plane and every record, or the paths given, on demand:

```
✗ error changes/c1/00-intake/request.md:1 secret: AWS access key id shaped string
! warning .ai/rules/learned.md:4 override: instruction-override phrase (a rule quoting an attack may add the allow marker)
✗ fail scan: 1 error, 1 warning in 214 files
```

The first run over this repository found a canary key in a closed record's evaluation evidence, placed there on purpose to prove an internal-failure report never echoes a credential; it is the first entry in the allowlist.

### Instincts: what a change learned

The learning phase now writes `15-learning/instincts.yml`: each instinct is a trigger an agent will recognise, one imperative action, a confidence from 0 to 1, and the finding or phase in the record that is its evidence. The learning gate's `instincts valid` check requires kebab-case unique ids, a trigger and an action, a confidence in range, and evidence; an empty list is a valid answer.

```bash
soft-foundry learn list                      # every record's instincts, highest confidence first
soft-foundry learn list --min-confidence 0.9
soft-foundry learn promote                   # copy those at or above the threshold into .ai/rules/learned.md
soft-foundry learn promote --dry-run
```

Promotion is the governance path for a proposed rule: it writes `.ai/rules/learned.md` (each entry with the change that learned it, its confidence, and its evidence) and refuses outside a change record on a change branch, so a lesson reaches the rules through a later change's record, never by the change that learned it applying it to the rules it works under. The threshold lives in `.ai/policies/learning.yml` (`0.8` by default; `--min-confidence` overrides it for one run). Implementation and exploration load `learned.md` with the baseline rules. Promotion is idempotent: an instinct already in the file is skipped by id.

### RED and GREEN evidence

`.ai/rules/testing.md` asks that a feature, fix, or refactor commit its failing test before the code that makes it pass. Verification can now bind that to git: a check in `06-verification/tests.yml` names the commit at which the test existed and failed as `red_commit`, and the test file as `test_path`:

```yaml
checks:
  - id: CHECK-001
    kind: tests
    command: bundle exec rake test
    result: pass
    evidence: evidence/tests.log
    criteria: [REQ-001]
    red_commit: 5d898e0c3f1a...     # the test existed and failed here
    test_path: test/feature_test.rb
```

The verification gate's `red evidence` check verifies the shape of that claim: the commit exists, precedes the verified commit, holds the test file, and `APP` or `INFRA` code changed after it. It does not re-run the test at the RED commit; the claim is the agent's, bound to a commit anyone can check out. Checks without `red_commit` are not checked, and a feature, fix, or refactor whose verification has none draws an advisory saying the failing-test-first evidence is not demonstrable.

### Fresh-context phases: `phase run`

Review and judgment exist to look at the work from outside it. Until now every record in this repository has said "performed by the interactive session, not a fresh-context agent" in its handoff notes. `soft-foundry phase run` makes the separation a process boundary:

```bash
soft-foundry phase run review                    # a fresh `claude -p` session with only the review skill in its prompt
soft-foundry phase run judge --shell codex       # or `codex exec`
soft-foundry phase run review --dry-run          # print the command and the prompt, launch nothing
soft-foundry phase run review -- --model opus    # pass extra arguments to the shell
```

The runner refuses what the gate would refuse afterwards (an exploring change, a phase already complete, a pending predecessor), so no session is spent on it. It moves `current_phase` to the phase so the guard applies the right skill, writes `executed_by` into the phase's handoff (runner, shell, `fresh_context: true`, start and finish times, exit status) before and after the session, and runs the phase's gate when the session returns. The agent fills the rest of the handoff itself; the prompt tells it not to touch `executed_by`, not to alter any other phase's evidence, and to record `blocked` rather than pretend.

A completed review or judgment whose handoff carries no `executed_by` from the runner gets an advisory: it was performed by whatever session was already open, and separation of duties rests on the handoff's notes. If the guard hook is not installed, `phase run` says so before launching, since the session's tool calls would then be checked by nothing.

### Lifecycle tracks: gated or iterative

The lifecycle above is a stage-gate process: intent, specification, threat model, and plan before code, evidence bound from the first commit. That is the right shape for assurance and the wrong shape for shaping a feature with a person by trying it. `.ai/workflow.yml` therefore declares two tracks that share the same phases and the same gate:

- **`gated`** runs every phase in lifecycle order. The specification locks when its phase completes. This is the repository default here.
- **`iterative`** starts with an **exploring** stage. The agent iterates with the person, deploys only to the development environment recorded in `.ai/repository.yml`, keeps `02-specification/` as a living draft, and appends each round to `changes/<slug>/exploration/iterations.yml`. Nothing from that stage is evidence, and the gate refuses to let any phase from implementation onward be complete while the change is exploring. When the person accepts the feature, `change vet` records who and at which commit; the specification is locked there, and the phases from implementation onward apply exactly as on the gated track. Discover, threat model, and plan are not required before implementation on this track (a change may still run them).

```bash
soft-foundry change new <slug> --track iterative   # status: exploring
# ... iterate, deploy to development, journal each round ...
soft-foundry change vet <slug>                     # the person's acceptance; locks 02-specification at HEAD
soft-foundry gate implement                        # hardening phases from here on, as on the gated track
soft-foundry change reopen <slug> --reason "..."   # back to exploring; phases from implementation onward reset to pending, files kept
```

`change vet` refuses until risk is classified, the journal has at least one entry, and intake and the specification are complete, committed, and pass their gates. After vet, a change to `02-specification/` fails the specification gate with a pointer to `change reopen`: a fix goes through remediation as usual, a reshaping goes back to the person. A change whose declared risk is `high` is always on the gated track (`tracks.forced_by_risk`); the gate reports the conflict on the intake phase and `change vet` refuses.

The exploring stage's skill is `.ai/skills/exploration/`. `check` verifies that it can write no commit-bound phase's directory, so the invariant that exploring produces a journal and never evidence is linted, not just stated. Deploying anywhere other than the development environment is a human boundary on either track.

### Closing a change record

A merged change's record has to be marked `closed`, or `soft-foundry ci` fails once that record has actually reached judgment: an un-closed record stays "live" to the gate checker, so a later edit to a path group its evidence covers will read as making that evidence stale.

```bash
soft-foundry change close <slug>                    # refuses unless the judged commit is merged
soft-foundry change close <slug> --force             # close anyway (e.g. a REJECTED change)
```

If judgment left an acceptance criterion `undischarged` pending a real-world event (production observation, etc.), `close` also refuses until a human confirms it — not a repository-derived fact, so not something an agent gets to assert on its own:

```bash
soft-foundry change request-discharge <slug> --pr <N>          # posts a PR comment naming what's outstanding
# a human replies on the PR: CONFIRMED: AC-060, AC-061
soft-foundry change close <slug> --pr <N>                       # reads that comment, discharges, then closes
soft-foundry change close <slug> --confirm AC-060 --confirm AC-061   # or confirm directly, no PR comment needed
```

### Go-live advisories and accessibility

A gate decides whether a phase's evidence is complete. Some things a gate cannot honestly decide still matter before a change ships: whether an independent review actually ran, whether anyone looked at the change through a screen reader, whether a person confirmed a criterion. Those are printed as advisories after the gate results by `gate`, `change status`, `ci`, and one last time by `change close`. They never change the exit code:

```
advisory: 2 issues to address before my-change goes live (informational, does not block the gate)
  ! warn review: independent review was skipped (the pull request is the review point); accessibility, security, and coding-standard conformance were not independently checked
  ! warn accessibility: 13-review/accessibility.md declares conformance N/A although the change declares an accessibility surface
```

The accessibility standard lives in `.ai/rules/accessibility.md`: WCAG 2.2 Level AA for any user interface, plus rules for command-line output, documents, and the evidence each lifecycle phase owes. A change declares that it has something a person perceives or operates with `surfaces.accessibility: true` in its `metadata.yml`; `change new` sets it automatically when `.ai/repository.yml` records a user-facing framework such as Rails or React. With the surface declared, the specification must carry an accessibility requirement, evaluation must record accessibility observations, and the review's `accessibility.md` must reach a conformance statement other than N/A, or the advisory says which one is missing. Level 5 of the maturity model requires the standard to be in force.

### Privacy and security policy conformance

The lifecycle already checks code against engineering security rules. A separate question is whether the change still matches what the governed application has told its users in its own privacy policy, security policy, and terms. `.ai/rules/policy-conformance.md` is that standard. Repository discovery records the documents the application publishes under `policies:` in `.ai/repository.yml`, and a document that does not exist is recorded `MISSING` rather than assumed. A change that alters what the application collects, shares, retains, protects, or promises declares `surfaces.policy: true` in its `metadata.yml`; `change new` sets it automatically when the profile records a published policy document. With the surface declared, the specification must carry a `category: policy` requirement naming the clause, and the review's `policy-conformance.md` must name the documents checked and reach a conformance statement other than N/A, or the advisory says which one is missing:

```
advisory: 2 issues to address before my-change goes live (informational, does not block the gate)
  ! warn policy: 02-specification/requirements.yml has no requirement with category: policy although the change declares a policy surface
  ! warn policy: 13-review/policy-conformance.md lists policy text changes owed; publishing them is a legal commitment awaiting a person: park the change with status: awaiting_human and record the decision under human_decisions in metadata.yml
```

When the review finds that the policy text itself must change for the code to be honest, that is a legal commitment under `.ai/policies/human-boundaries.yml`: the change is parked with `status: awaiting_human` until a person decides, and the decision is recorded under `human_decisions` in `metadata.yml`. Level 5 of the maturity model requires the standard to be in force.

Every line `soft-foundry` prints carries its outcome as a word (`pass`, `fail`, `warn`, `skip`, `created`, `conflict`) so the output means the same thing in a screen reader, a CI log, or a terminal that cannot render the glyph next to it.

## Updating

```bash
soft-foundry update          # checks RubyGems, reports current vs. latest; writes nothing
soft-foundry update --yes    # installs the newer version if one was found
```

This tool has no interactive prompts anywhere. `--yes` is the explicit second step that actually installs, the same way `--force` and `--dry-run` work elsewhere in this CLI: the plain command is always safe to run and never touches anything.

## Budget

Model API usage can get expensive, especially across a long-running change with multiple phases. `.ai/policies/budget.yml` declares spend limits (`max_usd_per_change`, overridable by a change's declared `risk` level), a threshold above which continuing is a financial commitment requiring human approval per `.ai/policies/human-boundaries.yml`, and a warning interval (`warn_every_usd`, default $10).

### Subscription or API key

Whether any of that applies depends on how usage is paid for, which is a fact about the machine running the work, not the repository:

- **Subscription.** A coding shell logged in to a Pro/Max/Team-style plan is a flat fee with nothing metered per token, so **no budget applies**. Soft Foundry says so and stays out of the way.
- **API key.** A provider key in the environment (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `XAI_API_KEY`, `OPENROUTER_API_KEY`; for `claude` also `ANTHROPIC_AUTH_TOKEN`, `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`) means usage is metered, so the budget policy applies.

Billing mode is detected from the environment wherever spend is about to start or a change begins: `soft-foundry shell <name>` (looking only at the variables that shell itself reads, so an OpenAI key does not make `claude` "metered"), `init`/`onboard` (including a `--maturity=deep` run, which shells into `claude`), `change new`, and `budget status`. The notice names what was detected and why, and `SOFT_FOUNDRY_BILLING=api` or `SOFT_FOUNDRY_BILLING=subscription` overrides the detection when it is wrong for your setup (a key exported for some other tool, say).

```
billing: API key (ANTHROPIC_API_KEY set, so usage is metered per token); the budget policy in .ai/policies/budget.yml applies
budget:  cap $50.00 per change (risk: medium); human approval required above $20.00
budget:  warns every $10.00 of recorded spend (next warning at $10.00)
budget:  my-change recorded so far: $0.00
```

### Ledger and warnings

This is policy and a ledger, not live metering: nothing in Soft Foundry today intercepts a real model API call, so nothing can enforce a cap automatically mid-call. Whoever executes a phase — a human or an agent — records what it cost:

```bash
soft-foundry budget record --change <slug> --phase 05-implementation \
  --provider openrouter --model "some/model" \
  --tokens-in 12000 --tokens-out 3000 --usd 0.08
soft-foundry budget status --change <slug>
```

Because the ledger is the only thing that moves, `budget record` is the moment warnings fire. With an API key, each entry that pushes the change's recorded total past another multiple of the warning interval prints a warning naming the amount and the cap; crossing the human-approval line prints that; going over the cap prints `OVER CAP` and exits non-zero. On a subscription, `record` still writes the entry (it is data) but says nothing budget-shaped.

`budget status` sums the ledger, states the billing mode, and with an API key compares the total against the policy cap for the change's declared risk, exiting non-zero when the recorded spend is over cap. On a subscription it shows the ledger for reference and always exits zero. `--usd` is optional per entry; entries without a cost are counted but excluded from the total, and `budget status` reports how many are missing.

The warning interval is a personal preference, so it is adjustable per machine without touching repository policy:

```bash
soft-foundry budget threshold            # show the interval in effect and where it comes from
soft-foundry budget threshold 25         # warn every $25 instead
soft-foundry budget threshold off        # no periodic warnings (cap and approval line still apply)
soft-foundry budget threshold default    # drop the local override, back to .ai/policies/budget.yml
```

The override lives in `.soft-foundry/budget.yml`, next to the runtime inventory and equally gitignored.

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