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

A gate passes only when the phase's required files exist with no `TBD` placeholders, the handoff is valid, nothing is blocking, the predecessor phase is complete, and commit-bound evidence is not stale. Evidence is stale when any file in the `APP`, `TESTS`, or `INFRA` path groups changed after the recorded commit, measured on the record's own branch while that branch exists (so a change stacked on another change's branch does not stale the earlier record) and on the worktree otherwise, and also when the specification was re-recorded after the evidence (its criteria are no longer the criteria). See `.ai/schemas.md`.

The specification is locked once recorded: on the gated track from the commit that recorded the completed specify phase (the newest commit touching its handoff while it says complete), on the iterative track from `change vet`. The gate's `specification locked` check fails on any later change under `02-specification/`, committed or not; a requirement change is made by rerunning the specification phase, after which every commit-bound phase is stale and is redone against the new criteria.

What a change may waive is bound to its declared risk. `.ai/workflow.yml` `waivable_by_risk` lists the phases a change of each risk may name in `skipped_phases` (shipped: low may waive discover, specify, threat_model, plan, attack, and learn; medium only discover and plan; high nothing). A phase not listed for the risk is required; an unclassified risk waives nothing but the globally optional phases; review and judgment are never waived, and `check` refuses a rule that names them. The gate reports this as `waivers permitted` on the first phase, so every `change status` and `ci` shows it, and `change close` refuses a record whose judgment is not complete (`--force` is the person's explicit decision to close without one).

`soft-foundry change status [slug] --json` prints the same state as data: every gate with each check's outcome and detail, the advisories, the recorded timeline, and the spend ledger, with the same exit code as the text form. `soft-foundry change list --json` prints every record with one cell per phase; closed records report what their handoffs recorded and are not gated again. Both carry `"version": 1` and are not yet a stable contract.

### Seeing it in a browser

```sh
soft-foundry ui                      # ui: serving http://127.0.0.1:PORT/#token=... (read-only; press Ctrl-C to stop)
soft-foundry ui --port 4877 --repo ~/dev/another-project
```

`soft-foundry ui` serves one page, to this machine only, for every Soft Foundry repository that has something going on. Open the link it prints: it carries a token, made up for that run, without which the page shows nothing. Treat the link like a password and do not paste it anywhere; it stops working when the server stops.

The page has two levels.

- **Repositories** is the home page: the repository you started the server in, any you named with `--repo`, and any in which a `claude`, `codex`, or `grok` session or a `soft-foundry` command is running. Each shows its open sessions (terminal, branch, change, recorded phase), its open changes, and how many are closed.
- **A repository** has its own pages, named at the top of each: **Changes**, one row per change record with a cell per phase (open changes are gated as you look, closed ones show what was recorded), and **Workflow**, the lifecycle as that repository defines it. Opening a change shows its sixteen gates in order; selecting a gate lists each check with its outcome, detail, and what it establishes. A change also shows its timeline, its spend against the budget caps, and any session or command running on it.

**Running** lists every session and command across all of them, each linked to its repository and change, and flags a `phase run` that started, never finished, and has no process. `soft-foundry ps` prints the same in a terminal.

Everything the page names is a link: a change, a phase, a repository, a commit. Hovering or focusing one shows what it points at (a gate's state, a phase's purpose, a change's status, a repository's sessions) and the file it lives in.

The page follows the records as they change, about every five seconds while the tab is visible. It only shows: nothing can be run or edited from it. The server answers GET on fixed routes, binds 127.0.0.1 with no option to bind anything else, names a repository only by an id it issued and never by a path, refuses requests that name another host or come from another site, and treats everything in a record as text. A session's phase is what its change's record says, not a reading of the session.

`soft-foundry check` lints the control plane itself. `soft-foundry ci` runs the lint plus every change record's gates, and `soft-foundry hooks install` wires it into a pre-commit hook. The GitHub Actions workflow runs the same two commands.

### Runtime enforcement: the guard hook

Every skill's `permissions.yml` declares what it may read and write, and `check` lints those declarations. `soft-foundry guard` enforces them while a coding shell is running: it is a Claude Code PreToolUse hook that reads each tool call, resolves the active change from the branch and the active skill from the change's status and `current_phase` (the track's stage skill while exploring), expands the skill's sets through the path groups, and decides.

```bash
soft-foundry hooks install --claude            # writes the hook into .claude/settings.json (shared)
soft-foundry hooks install --claude --local    # or .claude/settings.local.json (this machine only)
soft-foundry hooks install --codex             # writes the same hook into .codex/hooks.json; then trust it with /hooks inside Codex
soft-foundry hooks uninstall --claude          # removes only Soft Foundry's entry (likewise --codex)
soft-foundry doctor                            # reports which hosts have the hook and the mode in effect
```

The guard itself is host-neutral: it reads a JSON tool call on stdin and exits 2 to refuse. Claude Code and Codex share the hook file shape and the `PreToolUse` event. Codex names its shell tool `Bash` too, may send `command` as an array, and reports file edits as `apply_patch` (or under the `Edit`/`Write` aliases) with the patch text in `command`; the guard reads every path the patch adds, updates, deletes, or moves to and checks each against the write sets. Codex runs a project hook only after a person reviews and trusts it with `/hooks`. Grok (checked against 1.0.30) runs the Claude Code entry from `.claude/settings.json`, but only in a folder it trusts (`/hooks-trust` or `--trust`), and sends its own tool names: `write` and `search_replace` are checked as writes, `read_file` (path in `target_file`) as a read, and `run_terminal_command` as a shell command. `phase run --shell grok` reminds you of the trust step.

The mode is declared in `.ai/policies/enforcement.yml`: `block` by default since 0.21.0 (refuse the call: the hook exits 2 with the reason, and the refusal is logged to the machine-local `.soft-foundry/guard.log`); `warn` (report the violation, let the call through, log it); `off`. A maintainer's machine can override it in `.soft-foundry/enforcement.yml` or with `SOFT_FOUNDRY_GUARD=warn|block|off`, which wins over both. Neither can be reached from inside a guarded session: the guard treats its own configuration (`.ai/policies/enforcement.yml`, `.soft-foundry/enforcement.yml`, and the hook entries in `.claude/settings.json`, `.claude/settings.local.json`, and `.codex/hooks.json`) as denied to every skill, for the write tools and for any shell command that names one, and a command's environment ends with the command. Outside a change branch, or once a change is closed, nothing is guarded. `doctor` and `hooks install` print the mode in effect and where it comes from.

What is checked: Edit, Write, MultiEdit, NotebookEdit (and Grok's `write` and `search_replace`) against the write and deny_write sets; Read (`read_file`) against deny_read only; Bash (`run_terminal_command`) against the deny sets only, because the guard cannot know what a command writes, so it refuses a command that names a denied path and passes everything else. A restriction the guard cannot see is still policy the agent must honor, as `AGENTS.md` says. Every refusal or warning names the tool, the path, the skill, and the mode:

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
soft-foundry phase run judge --shell grok        # or `grok -p` (runs the Claude guard entry only in a folder Grok trusts; the runner says so)
soft-foundry phase run review --dry-run          # print the command and the prompt, launch nothing
soft-foundry phase run review -- --model opus    # pass extra arguments to the shell
```

The runner refuses what the gate would refuse afterwards (an exploring change, a phase already complete, a pending predecessor), so no session is spent on it. It moves `current_phase` to the phase so the guard applies the right skill, writes `executed_by` into the phase's handoff (runner, shell, `fresh_context: true`, start and finish times, exit status, and the session's `session_id` and `cwd`) before and after the session, and runs the phase's gate when the session returns. The agent fills the rest of the handoff itself; the prompt tells it not to touch `executed_by`, not to alter any other phase's evidence, and to record `blocked` rather than pretend.

**A different provider for review and judgment.** Both skills declare `prefer_different_provider_from: [implement, remediate]` in their `skill.yml`. Without `--shell`, `phase run review` and `phase run judge` read which provider wrote the code (the handoff's `resolved_model.provider`, else the shell `phase run` recorded) and pick the first installed shell, in the order claude, codex, grok, on another provider:

```
shell: codex (implementation ran on anthropic; the review skill prefers a different provider)
```

If a named phase's provider is not recorded, the known ones are still avoided and a `! warn shell:` line says which is missing; if none is known, or no installed shell runs on another provider, the warning says so and the first installed shell is used. A provider name it does not recognize falls back to the shell `phase run` recorded. `--shell` always wins. A review or judgment that ran on the same provider anyway gets a go-live advisory. "Installed" means on `PATH`, not logged in: if the chosen shell cannot start, name another with `--shell`.

**Findings name the failure they prevent.** Every review finding states the concrete input or state and the wrong result it leads to. In the review handoff, every finding above `minor` (whatever its severity word) carries it as `failure:`, and the gate's `findings explained` check fails without it; a finding that cannot name one is minor. Asking for defensive additions (validation, rescues, or nil checks for states the code cannot reach) is not blocking or major unless the reviewer names the input that reaches the state.

Every phase whose skill declares `evidence: commit_bound` (verification, evaluation, attack, review, judgment) prefers a fresh session the same way: `soft-foundry phase run verify`, `evaluate`, or `attack` works like `review` and `judge`. A completed one whose handoff carries no `executed_by` from the runner gets an advisory on every gate run: it was performed by whatever session was already open, most likely the one that implemented the change, and separation of duties rests on the handoff's notes. If the guard hook is not installed, `phase run` says so before launching, since the session's tool calls would then be checked by nothing.

The session ID lets you get back into a phase run's session (`soft-foundry resume <change> <phase>`). Claude Code and Grok are handed one up front (`--session-id`, `-s`); Codex picks its own, so the runner takes it from the session ledger when the session hook is installed (see "Finding and resuming sessions"), and leaves it null otherwise.

### Panels: independent drafts, an argument, one consensus

For a hard question, run a phase as a panel of two to four agents instead of one:

```bash
soft-foundry phase run specify --panel claude,grok                  # two members: claude-1 and grok-1
soft-foundry phase run remediate --panel claude,grok,claude,grok --max-rounds 4
soft-foundry phase run review --panel claude,grok --dry-run         # members, round limit, most sessions, commands
soft-foundry phase run plan --panel claude,grok --shell-arg claude=--permission-mode=acceptEdits --shell-arg grok=--always-approve
                                                                    # each shell's own headless flags; `-- args` go to every member
```

1. **Independent round.** Every member starts at once in its own fresh session with the phase's skill. Each writes its findings, theories, and proposed outcome in its own temporary folder outside the repository, which no other member is told about. Once every member is done, the runner copies the drafts into `<phase>/panel/<member>/`. A member that exits without a draft is reported, and with fewer than two drafts the panel fails rather than splits.
2. **Argument rounds.** Members take turns, resuming their own sessions (Claude Code and Grok; Codex starts fresh and reads the files). Each appends one section to `<phase>/panel/ARGUMENT.md`. A member that agrees ends its section with `agree: <one sentence>`. When every member's section in a round ends with the same sentence, the panel has agreed. The runner reads only the text each member appended during its own turn, so a line written under another member's name does not count, and rewriting earlier text spoils the round.
3. **Consensus.** The first member named writes the phase's normal outputs. They open with a summary of at most ten lines and cite every draft folder. The runner is the authority on what changed, because a shell command can always hide a path from the guard. Between stages it compares every file git can see in the repository. Nothing may change during the independent stage, since drafts go outside the repository. In an argument turn only `ARGUMENT.md` may change, and only by appending; rewriting earlier text spoils that round. In the consensus only the phase's own files outside `panel/` may change. Anything else fails the run, as do two byte-identical drafts and a consensus session that exits non-zero. A failed panel is `blocked` with `panel failed:` lines and is not parked for a person, because there is nothing to decide.

What this does not do: members are ordinary agent sessions running as you, not sandboxed processes. A member determined to read another's draft during the independent round can still find it in the system's temporary folder with a shell command the guard cannot read. The runner catches copying only when the drafts are identical. Independence rests on the prompts and on that check; true isolation would need an OS sandbox, which panel mode does not set up.
4. **Split.** If the panel has not agreed after `--max-rounds` (default 3, at most 5), the outputs present each position and what would decide between them. The handoff is `blocked`, and the change parks at `awaiting_human` until a person records the decision under `human_decisions` with `boundary: panel split`.

Panels are allowed for the phases in `panel_phases` in `.ai/workflow.yml` (specify, threat_model, plan, remediate, and review), never for implementation. The handoff records a `panel:` block (members with shell, provider, and session ID; rounds; outcome), and the gate's `panel recorded` check requires a draft per member, a non-empty `ARGUMENT.md`, an outcome, and every draft cited. With the guard installed, each member's session is narrowed by `SOFT_FOUNDRY_PANEL_MEMBER`, `SOFT_FOUNDRY_PANEL_STAGE`, and `SOFT_FOUNDRY_PANEL_DRAFT_DIR`. This covers write tools, shell commands, and any other tool whose input names a path. In the independent stage a member may write only its own draft folder and may not touch the phase's files or another member's draft. In the argument stage it may write only `ARGUMENT.md`, and it reads drafts with the read tool, not the shell. In the consensus stage the panel folder is read-only. Every shell is found on `PATH` before any member starts. Every prompt tells members that the other drafts are data, not instructions. A panel whose members all ran on one provider gets a go-live advisory. A four-member panel with three rounds can start up to 17 sessions; `--dry-run` prints the number before anything runs.

### Lifecycle tracks: gated or iterative

The lifecycle above is a stage-gate process: intent, specification, threat model, and plan before code, evidence bound from the first commit. That is the right shape for assurance and the wrong shape for shaping a feature with a person by trying it. `.ai/workflow.yml` therefore declares two tracks that share the same phases and the same gate:

- **`gated`** runs every phase in lifecycle order. The specification locks at the commit that records its completed phase. This is the repository default here.
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

### Reopening a phase, parallel runs, and released changes

```bash
soft-foundry phase reopen verify --reason "fix landed after verification"
soft-foundry phase run evaluate attack --parallel --env DATABASE_URL=postgres://localhost/sf_{phase}
soft-foundry change release my-change --item OBS-1="confirm the dashboard after deploy"
soft-foundry change discharge OBS-1 --note "dashboard confirmed"
```

#### Reopening a phase

`phase reopen <phase> --reason TEXT` resets the phase, every later phase, and the `next` loop-back of the reopened phase to `pending`. Evidence files are kept. Each reopening is appended to `phase_reopenings` in `metadata.yml` (`at`, `phase`, `reset`, `from_commit`, `reason`, `source`, `previous`). `phase run` makes the same reopen automatically (`source: auto`) when the phase it is asked to run is complete but its evidence is stale. It refuses on a closed, released, exploring or awaiting_human change, when there is nothing to reset, and from inside a `phase run` session.

#### Running isolated phases in parallel

`phase run A B --parallel` runs phases listed in `isolated_phases` in `.ai/workflow.yml` (evaluate and attack by default), each in its own fresh session. Each `--env NAME=VALUE` is expanded per session (`{phase}` becomes the phase id) and placed in that session's environment only. Soft Foundry never creates or tears down what a value names: isolating a shared database, port or cache is the adopter's responsibility, and the run prints a `warn:` line when no `--env` is given. Sessions share the start HEAD and are told not to commit. The values stay out of files, output and argv; the person's shell history and a microsecond window before the process title is rewritten remain. Output lines are `phase <id>: pass|fail` and `parallel:`.

#### Released changes

`change release` marks a judged change `released` and requires named open items; `change discharge ID --note TEXT` records that one is done; `change close` then closes it. `ci` passes on a merged released change while items are open and lists them, and still fails on `main` for a merged change that is neither `closed` nor `released`. `closed` remains the only end state.

**Residual.** `phase run` sets `SOFT_FOUNDRY_PHASE` so `phase reopen`, `change release` and `change discharge` refuse inside a session. This guards against accident, not a sandbox: a session that unsets the variable in a shell is not stopped.

### Closing a change record

A merged change's record has to be marked `closed`, or `soft-foundry ci` fails once that record has actually reached judgment: an un-closed record stays "live" to the gate checker, so a later edit to a path group its evidence covers will read as making that evidence stale. A record closes only with a completed judgment (`.ai/workflow.yml` `rules.final_judgment_required`); `--force` closes one without, as the person's recorded decision.

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

### Scoped verification: re-run only what a change can affect

By default any code change makes every record's commit-bound evidence stale and every verify re-run everything. A change can narrow that:

- **Scope.** `scope:` in a record's `metadata.yml` (`change new <slug> --scope GLOB`) lists the paths the change owns. Its evidence goes stale only when a changed code file is in that scope, in the repository's `shared_core` (globs in `.ai/repository.yml`, for example the base controller, the user model, auth), or claimed by no active record. Code inside another active record's scope does not stale it. A record with no scope behaves exactly as before.
- **Sizing.** `soft-foundry change size [slug] --phase verify|evaluate|attack` computes the check size from the diff and `.ai/policies/check-sizing.yml`: targeted checks plus one full run before merge when every changed code path is in the change's scope or in another active record's scope (that record owns and checks it), or the full suite at verify when shared core is touched, a changed path is claimed by no active record, or the change is unscoped; evaluate and attack run the touched doors plus a smoke test, and sweep every route only when a changed path matches the repository's `access_control` globs or no declaration exists. The gate refuses evidence that records a smaller size than the diff computes.
- **Full-suite reuse.** `06-verification/tests.yml` may record a `full_suite:` run keyed by the evidence commit's tree hash, or cite another record's run on the same tree, so identical code is not re-tested for each record. A passing check shows a recorded run names this tree with a recorded outcome, not that the suite passed; Soft Foundry never runs your tests.
- Editing a declaration (scope, `shared_core`, `access_control`, the sizing policy) after the evidence commit stales the evidence, so a narrowed declaration cannot launder an old change. A git failure while measuring reads as stale, never as unchanged. A recorded `git.branch` is trusted as the place to measure only when it is the checked-out branch, descends from it, or strictly descends from the evidence commit; otherwise the checked-out HEAD is the measure, and editing `git.branch` after the evidence commit makes the evidence stale.

Known limits of scoped verification, accepted by the maintainer: (1) a record whose author sets `git.branch` in the record to a branch created at a later commit looks like a legitimately stacked branch, so code landing afterwards on the checked-out branch can go unmeasured; the author already controls the evidence the gate reads, and the gate checks structure, not truth. (2) An active record scoped to `**` claims every path, so it keeps other records' evidence current; the go-live advisory names it, and closing or narrowing that record makes the others stale again. (3) A recorded size is refused only at verification; evaluation and attack record theirs but the gate does not compare them.

### Everyday shortcuts: type and risk, blocked runs, summary, hidden characters

```bash
soft-foundry change new my-change --type fix --risk medium   # record both at creation
soft-foundry change summary my-change                        # where the change is now
```

#### Type and risk at creation

`change new --type TYPE --risk RISK` writes both to `metadata.yml`. Types: feature, fix, refactor, docs, infrastructure, security, chore. Risks: low, medium, high. An unknown value is refused before anything is created, with the allowed list; leaving a flag out keeps the placeholder as before.

#### A session that completes with blocking items

When a `phase run` session writes its handoff `status: complete` while `blocking` is not empty, the runner changes the status to `blocked`, keeps the blocking entries, adds a sentence to `notes`, and prints a `blocked:` line naming the phase. The same holds for `--parallel` runs. The gate still fails a hand-edited `complete` handoff that lists blocking items.

#### Latest state of a change

`change summary [slug]` prints recorded facts only, one per line with a stable prefix: `change:`, `phase:`, a `phase-status:` line per phase, `findings:`, `blocking:` and `owed:`. It runs no gate and writes nothing. An unreadable handoff is shown as `unreadable` with the reason and the rest still prints.

#### Quoting hidden characters in evidence

Payloads that contain invisible, zero-width, bidirectional or control characters go into evidence as visible escapes (`<U+200B>`, `<U+202E>`) or are built inside a script with an escape such as `\u{200B}`, never pasted raw. A raw one fails the `content clean` gate, which is unchanged. The adversarial-testing, verification and review skills say so.

#### Access-control parity

When the repository profile declares `access_control` globs and a change touches a matching path, verification states the protection each check ran with (`protection: in_force | disabled | not_applicable`, plus a `protection_note` for `disabled`) in `tests.yml`. The `protection stated` check requires the statement; whether it is true is for review (`.ai/rules/access-control-parity.md`). It names no framework and is not applicable to a repository that declares no `access_control`.

### Proving the gate: harness evals

A gate that has never refused anything has unknown power. `.ai/harness-evals/cases/` holds executable cases that measure the control plane itself, and `soft-foundry eval` runs them:

```sh
soft-foundry eval                                   # every gate case; one status line each, then a summary; exit 0 only if all pass
soft-foundry eval --case judgment-waived --json     # some cases, as data
soft-foundry eval --live --shell claude             # also the live cases, each in a fresh session through `phase run`
```

A **gate case** plants a defective change record in a scratch git repository carrying this repository's control plane (a review finding with no failure named, evidence left stale by a code change, a placeholder in a result, an invisible character, a secret-shaped canary, a RED commit that is the GREEN commit, a waived judgment, an attack waived at medium risk, an implementation recorded while exploring, a requirement edited after the lock, a handoff complete with a blocking condition) and asserts which gate check refuses it; a well-formed control must pass. The shipped suite runs in about ten seconds, `ci` runs it after the control-plane lint, and it ships with the control plane, so an application repository proves its installed gate with the same command. A **live case** plants a defect in a scratch application and a record that claims it is fine, runs the case's phase (review, in the shipped case) in a fresh session on the shell you name, and passes when the session's findings name the defect; a miss is recorded as the result, with the shell and the model the session wrote. Live cases run only with `--live` and need a logged-in shell.

```
✓ pass eval judgment-waived: intake waivers permitted fail, as expected
- skip eval review-finds-planted-defect: live case; run `soft-foundry eval --live --shell claude|codex|grok --case review-finds-planted-defect`
✓ pass eval: 12 passed, 0 failed, 0 errors, 1 skipped
```

Every skill is denied `.ai/harness-evals/` (read and write), so the agents being measured cannot see or tailor the cases, and `eval` prints ids and outcomes, never case content. `soft-foundry check` lints every case; `.ai/harness-evals/README.md` describes the case format and the tokens (`${COMMIT}`, `${APP_FILE}`, secret-shaped and invisible canaries the runner builds so that no case file carries one). Scratch repositories live under the system temp directory and are removed when the case ends, exceptions included; a live session runs as you in that directory with the host's own permission mode, which is the same limit `phase run` has.

## Updating

```bash
soft-foundry update          # checks the GitHub repository's latest release; writes nothing
soft-foundry update --yes    # installs it under the Ruby that runs soft-foundry, from any repository
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

### Finding and resuming sessions

`ps` shows the shells open now. To find one that has finished, or one open in a terminal you have lost track of, install the session hook once:

```bash
soft-foundry hooks install --sessions     # user level: Claude Code, Codex, and Grok, plus a find-session skill
soft-foundry sessions qr code             # sessions whose prompts, folder, branch, or change match every word
soft-foundry sessions --change ui-links --phase review --agent codex
soft-foundry sessions ledger --json       # the same as data
soft-foundry resume ui-links review       # print the newest matching resume command
soft-foundry hooks uninstall --sessions   # remove the hooks and the skill; the ledger stays until you delete it
```

The hook is a `UserPromptSubmit` entry in `~/.claude/settings.json`, `~/.codex/hooks.json`, and `~/.grok/hooks/soft-foundry-sessions.json` that runs `soft-foundry session log`. It prints nothing and always succeeds, so it can never block a prompt or reach the agent's context. Codex runs it only after you review and trust it with `/hooks` inside Codex. The `find-session` skill (`~/.claude/skills/find-session/`, which Grok also reads, and `~/.agents/skills/find-session/` for Codex) lets you ask an agent "find the session where we worked on the QR generator" and get the resume command back.

Each match prints its status as a word (`resumable`, `folder missing`, or `transcript missing`) and the exact command to paste, for example `cd /path/to/repo && codex resume 019a…`. Neither `sessions` nor `resume` starts a session.

**What the ledger keeps, and where.** `~/.soft-foundry/sessions.jsonl` (or `SOFT_FOUNDRY_SESSIONS`), one line per session, readable only by you: the agent, session ID, folder, repository, branch, the change and phase that branch is on, the transcript path the agent reported, first and last prompt times, and the first and latest prompt cut to 140 characters with secret-shaped strings (API keys, tokens, private keys) masked. Nothing is sent anywhere. It is an index, not a backup: a session can be resumed only while its agent still has the transcript. A prompt whose hook payload is larger than 1 MB is skipped (the session is recorded at its next ordinary prompt), and a folder whose name contains control characters is stored without them, so such a session reports `folder missing`. Delete the file to forget everything recorded.

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