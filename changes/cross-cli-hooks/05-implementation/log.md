# Implementation Log

## Changes made
- `test/cross_cli_hooks_test.rb` (new, committed first at `2357158` as RED): seven tests for patch paths, the array and alias forms, array Bash commands, the Codex install and uninstall, the combined doctor line, Grok in the runner, and the per-shell warnings. `test/guard_test.rb`: the doctor expectation updated to the combined line. `test/phase_runner_test.rb`: the Claude warning's new wording.
- `lib/soft_foundry/guard.rb`: `PATCH_TOOLS`, `PATCH_HEADER`, `command_text` (array to text), `patch_paths`; the write branch now handles a file path or a patch and reports every offending path.
- `lib/soft_foundry/hooks.rb`: `CODEX_GUARD_MATCHER`, `codex_hooks_path`, `install_codex`, `uninstall_codex`, `codex_installed?`; the Claude methods now share `install_into`, `uninstall_from`, and `installed_at`.
- `lib/soft_foundry/phase_runner.rb`: `grok` in `SHELLS` (`-p`), `HOOKED_SHELLS`.
- `lib/soft_foundry/cli.rb`: `hooks install|uninstall --codex` with the trust note and the `--local` refusal; one `guard hook` doctor line; per-shell guard warnings in `phase run`; help text.
- `README.md` (guard and runner sections), `AGENTS.md` (the enforcement paragraph names Codex).
- `.codex/hooks.json` (new, committed): the guard hook for this repository. `.ai/rules/learned.md`: two instincts promoted from control-plane-scan.
- Version bumped to 0.15.0.

## Decisions
See `decisions.md`.

## Deviations from plan
None. See `deviations.md`.

## Lessons
- Reading the real contract first mattered: the guard needed a patch parser, not a field-name adapter, because Codex does not send a file path for edits at all.
- Two hosts sharing one hook shape made the installer smaller, not larger: one `install_into` with a matcher per host.
- Grok's honest answer is "policy only", and saying it at launch is worth more than pretending a hook exists.

## Challenges
None substantive.
