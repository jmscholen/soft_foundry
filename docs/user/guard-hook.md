# The guard hook: installing it, keeping it current, and reading its refusals

Provenance: requirements REQ-GDH-001, REQ-GDH-002, REQ-GDH-004 (`changes/guard-docs-and-hooks/00-intake/request.md`); evaluation journeys EVAL-001, EVAL-002, EVAL-003, EVAL-004, EVAL-005, EVAL-008, EVAL-009 (`changes/guard-docs-and-hooks/07-evaluation/`), and factory-readiness EVAL-004 for the live-eval invocation. Introduced by change `guard-docs-and-hooks`; last verified by change `guard-docs-and-hooks` at commit `2af76ba`. The README's "Runtime enforcement: the guard hook" section is the reference text; this page is the task-by-task version.

## Who this is for

- A maintainer who installs Soft Foundry's guard in a repository, or already has it and wants the current install.
- A maintainer who changes the guard's mode on their own machine.
- An agent session, or the person reading its transcript, who meets a refusal and wants to know why and what to do.

## Install or update the hook

1. From the repository root, run `soft-foundry hooks install --claude` (add `--local` to write `.claude/settings.local.json` for this machine only). For Codex, run `soft-foundry hooks install --codex`, then open Codex in the repository and trust the hook with `/hooks`.
2. Read the output. It names each entry it installed and the mode in effect:

   ```
   installed guard hook in .claude/settings.json (PreToolUse: Edit|Write|MultiEdit|NotebookEdit|Read|Grep|Glob|Bash)
   installed post-call check in .claude/settings.json (PostToolUse: Bash; restores the guard's own configuration if a command changed it)
   guard mode: block (repository policy (.ai/policies/enforcement.yml))
   ```

3. Run `soft-foundry doctor`. The guard line reads `pass guard hook (claude: installed, codex: installed; mode: block, repository policy (.ai/policies/enforcement.yml))`, with `not installed` for a host that has no entry. When neither host has one, the line is `fail` and names the install command.

**Already installed before 0.21.0?** Run the same command again. The old entry has a matcher without `Grep` and `Glob` and no `PostToolUse` entry, so the two search tools are not checked and the post-call restore is not active. The rerun replaces the one guard entry's matcher, adds the `PostToolUse` entry, keeps every other hook and key in the file, clears a baseline left by an interrupted command, and changes nothing on a second run. `hooks uninstall --claude` removes only Soft Foundry's entries.

Codex gets a `PreToolUse` entry only (matcher `Bash|apply_patch|Edit|Write`). The post-call restore is installed for Claude Code, and for Grok, which runs the Claude Code entry.

## Change the mode on your machine

The repository policy in `.ai/policies/enforcement.yml` is `block`. To use another mode on your own machine, write `.soft-foundry/enforcement.yml` (gitignored, same shape as the policy) or set `SOFT_FOUNDRY_GUARD`, which wins over both files:

```yaml
guard:
  mode: "off"
```

Quote `off`. A bare `off` is read by YAML as the boolean false, which is not a mode, so the file is ignored and the next source applies: under a `block` policy an override saying `mode: off` leaves the mode at `block`. `SOFT_FOUNDRY_GUARD=off` needs no quoting; a value the variable does not recognise is ignored. `doctor` prints the mode in effect and its source (`repository policy`, `machine-local override`, or `SOFT_FOUNDRY_GUARD environment variable`).

Neither file can be written from inside a guarded session: the guard refuses writes to its own configuration from every skill. Make the change in your own shell between tool calls, and it stands.

## Edit the configuration by hand after an interrupted command

Before each shell command the guard records its configuration in `.soft-foundry/guard-baseline.yml`; the check after the command restores anything that changed and consumes the baseline. A shell command interrupted before its check leaves the baseline behind. One older than thirty minutes is refreshed at the next shell call, but inside that window a hand edit would be read as a change during a call and restored at the next check.

1. Run `soft-foundry guard --after` once. It consumes the baseline and prints nothing when nothing changed.
2. Make your edit. Running `hooks install` or `hooks uninstall` instead also clears the baseline, since both are your own change to that configuration.

## Read a refusal

Every refusal names the tool, the path, the skill, the mode, and where the override is documented, and appears as one line in `.soft-foundry/guard.log`:

```
✗ fail guard: Grep .ai/harness-evals searches inside evaluation's deny_read set; the evaluation skill's permissions.yml does not allow it (mode: block, .ai/policies/enforcement.yml; a maintainer's machine-local override is documented in README.md)
2026-11-06T12:41:45Z block Grep skill=evaluation paths=.ai/harness-evals searches inside evaluation's deny_read set
```

| The message says | What happened | What to do |
| --- | --- | --- |
| `is not in <skill>'s write set` or `is in <skill>'s deny_write set` | A write tool named a path the active skill may not write. | Write only where the skill's `permissions.yml` allows; another skill's job is another phase. |
| `outside the repository; no skill may write there` | A write tool named a path outside the repository. | Keep working files inside the repository, under the phase directory. |
| `searches inside <skill>'s deny_read set` | Grep or Glob pointed at a denied directory, judged by the `path` or the pattern's static prefix. | Search a narrower path the skill may read. |
| `names protected policy or harness material` | A shell command named `.ai/policies/` or `.ai/harness-evals/`, existing file or not. | Read a policy file with the Read tool if the skill may; harness evals are denied to every skill. |
| `names a path <skill> may neither read nor write (a shell command may name what the skill may read)` | A shell command named a deny_write path the skill may not read. | A command may name what the skill may read; use the Read tool for anything else the skill is allowed. |
| `names the guard's own configuration; no skill may touch it from the shell` | A shell command named the policy, anything under `.soft-foundry/`, or a hook settings file. | Read those files with the Read tool, which is allowed; never from the shell. |
| `could not be decided (...); refusing it` | The guard fails closed: an unknown `~user`, a NUL byte, an unreadable tool call, or today a `cd` or `pushd` out of the repository followed by a redirection in the same segment. | Spell the command so it can be decided: `cd /tmp && ls` instead of `cd /tmp 2>/dev/null && ls`. |
| `changed during the tool call and were restored to the state before it (tamper logged ...)` | A shell command changed the guard's configuration; the post-call check restored it. | The change was undone and logged. If it was yours, make it in your own shell between tool calls. |

An Edit whose `old_string` does not occur in the file fails in Claude Code with "String to replace not found" before the guard sees it, and leaves no guard log line; that is the host's validation, not a refusal.

## Run a live harness eval unattended

On Claude Code, pass the shell's own flags after `--` so the fresh session may write the phase directory. Without them the review session finds the planted defect but cannot write `13-review/`, and the case fails with `0 findings recorded`.

```sh
soft-foundry eval --live --shell claude --case review-finds-planted-defect -- --allowedTools "Read Write Edit Glob Grep Bash" --permission-mode acceptEdits
```

## What the guard does not do

A path held in a shell variable or produced by a command substitution is invisible to the pre-call check; a root-wide read (`grep -r .`, Grep with no path) reaches denied material; a detached process writing after the check, one command that rewrites the configuration and the baseline together, and a committed weak policy get past the restore. The gate's staleness check and review are the backstop. A restriction the guard cannot see is still policy the agent must honor.
