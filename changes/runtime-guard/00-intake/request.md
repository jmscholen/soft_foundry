# Change Intake

## User intent
After evaluating ECC (affaan-m/ECC) against Soft Foundry, the maintainer asked what to add from what ECC does better and then said "ok, lets do the 5 recommended additions." This is the first: runtime enforcement of skill permissions. Every skill's `permissions.yml` declares read, write, deny_read, and deny_write sets; `check` lints them; nothing enforces them while a coding shell runs. ECC shows the mechanism works: a PreToolUse hook that reads the tool call and exits 2 to refuse. The repository profile has recorded `governance.skill_permissions: PARTIAL` with the finding `declared_and_linted_not_enforced_at_runtime` since discovery, and the roadmap has host-level enforcement generated from `permissions.yml` as its next item.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-GRD-001.** `soft-foundry guard` reads a Claude Code PreToolUse payload from stdin and decides it against the active skill's expanded permission sets: Edit, Write, MultiEdit, and NotebookEdit are violations when the path is in deny_write or not in write, or lies outside the repository; Read is a violation only when the path is in deny_read; Bash is a violation only when the command names a path in a deny set, because the guard cannot know what a command writes. Every other tool is allowed.
- **REQ-GRD-002.** The active skill is resolved from the branch: the change record whose slug matches the branch (with or without the `change/` prefix); while the change is `exploring`, the track's stage skill; otherwise the skill of `current_phase`. With no control plane, no git repository, no record for the branch, a closed or judged change, or a `current_phase` that is not a lifecycle phase, everything is allowed and the reason is available.
- **REQ-GRD-003.** The mode is `warn` (report on stderr, exit 0, append to the machine-local `.soft-foundry/guard.log`), `block` (report on stderr, exit 2), or `off` (silent, exit 0). It resolves from `SOFT_FOUNDRY_GUARD`, then `.soft-foundry/enforcement.yml`, then `.ai/policies/enforcement.yml`, then the default `warn`; an unrecognised value is ignored at that level. Allowed calls are silent in every mode.
- **REQ-GRD-004.** A payload that is not a JSON object with a `tool_name` is refused with exit 2 in block mode and reported with exit 0 in warn mode; the guard never raises to the shell.
- **REQ-GRD-005.** `soft-foundry hooks install --claude [--local]` writes a PreToolUse entry with matcher `Edit|Write|MultiEdit|NotebookEdit|Read|Bash` into `.claude/settings.json` or `.claude/settings.local.json`, creating the file if needed, keeping every other key and hook, and replacing any prior Soft Foundry entry (recognised by the `soft-foundry:guard` marker in its command) so repeated installs leave one entry. `hooks uninstall --claude [--local]` removes only that entry. Invalid JSON or a symlinked settings file is refused.
- **REQ-GRD-006.** `doctor` gains a `claude guard hook` line that carries pass or fail as a word, the mode in effect and its source, and the install command when missing.
- **REQ-GRD-007.** `check` reports an error when `.ai/policies/enforcement.yml` exists with a `guard.mode` outside `warn`, `block`, `off`, or is not valid YAML; the file is optional.
- **REQ-GRD-008.** `.ai/policies/enforcement.yml` ships in the control plane with `mode: warn` and a comment stating what is checked and what is not. `README.md` gains a section, `AGENTS.md` names the guard in its enforcement paragraph, and `.ai/README.md` lists the policy.
- **REQ-GRD-009.** This repository's profile records `governance.skill_permissions: PASS` with the rationale, `.ai/maturity.yml` carries the assessment rule that says when that capability is PASS, and the version is 0.10.0.
- **REQ-GRD-010.** Everything else is unchanged: all prior tests pass, `ci` against this repository's history passes, and the pre-commit `hooks install` behaves as before.

## Constraints
- The guard must answer quickly and never crash the shell: any failure inside it becomes a decision (fail closed in block mode, a warning in warn mode).
- `.claude/settings.json` belongs to the repository's owners; the installer may only add or remove its own entry and must preserve everything else.
- The mode is a repository policy with a machine-local override, following the budget threshold's pattern, so `.ai/policies/` stays protected from every skill's write set and a machine can still run in block mode without a commit.
- Every line the guard or doctor prints carries its outcome as a word per `.ai/rules/accessibility.md`.
- Nothing machine-local is committed: the log and the local override live under the gitignored `.soft-foundry/`.

## Non-goals
- Enforcing read allow-lists. Read lists are advisory context; only deny_read is enforced.
- Parsing shell commands for their real effects. Bash is deny-only by design and the policy file says so.
- Hooks for shells other than Claude Code. Codex and others keep the policy-only path `AGENTS.md` already describes.
- Enforcement of budget, human boundaries, or anything beyond file and path permissions.

## Task classification
Feature: a `Guard` module, a `guard` CLI command, `hooks install --claude` and `hooks uninstall --claude`, a doctor line, a `check` validation, a policy file, documentation, a profile and maturity update, tests.

## Initial risk
low. The guard reads one JSON document from stdin and answers with an exit code; its only writes are an append to a gitignored log and, on install, a JSON settings file through SafeWrite. In warn mode (the shipped default) it changes no behaviour of the shell. Existing tests and change records pass unchanged.
