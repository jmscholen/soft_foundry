# Implementation Log

## Changes made
- `lib/soft_foundry/guard.rb` (new): `Guard.mode` (environment, local override, policy, default), `Guard#active` (branch to record to skill, with the reason when nothing applies), `Guard#decide` (the per-tool rules), `Guard#log` (append-only, never raises), the Bash token heuristic `shell_paths`.
- `lib/soft_foundry/cli.rb`: `input:` on the constructor; the `guard` command (mode, payload parse, fail-closed rule, the two message shapes); `hooks install [--claude [--local]]` and `hooks uninstall --claude [--local]`; the `claude guard hook` doctor line with the mode folded in so every line keeps its status word; help text.
- `lib/soft_foundry/hooks.rb`: `install_claude`, `uninstall_claude`, `claude_installed?`, `guard_entry?`, JSON settings read/write through `SafeWrite`; the pre-commit hook unchanged.
- `lib/soft_foundry/check.rb`: `check_enforcement` (mode value, YAML validity); `require "yaml"` and the guard so it stands alone.
- `.ai/policies/enforcement.yml` (new): `guard.mode: warn` with the comment that states the rules and their limits.
- `.ai/repository.yml`: `governance.skill_permissions: PASS` with rationale. `.ai/maturity.yml`: the assessment rule for that capability. `.ai/README.md`: the policies row names the file.
- `README.md`: "Runtime enforcement: the guard hook". `AGENTS.md`: the enforcement paragraph names `hooks install --claude` and the Bash limitation.
- Tests: `test/guard_test.rb` (16 tests: the decision matrix per tool and skill, outside-repository paths, no record and closed change, phase selects skill, exploring uses the stage skill, mode precedence, `check` on a bad mode, the hook command in warn, block, and off, fail-closed on bad input, install idempotence with other settings preserved, `--local`, invalid JSON refused, doctor line).
- Version bumped to 0.10.0.

## Decisions
See `decisions.md`.

## Deviations from plan
None. See `deviations.md`.

## Lessons
- The first full-suite failure was the accessibility standard doing its job: a `guard mode:` line under `doctor` with no status word broke `StatusWordTest`. The mode was folded into the check line rather than exempted.
- A guard's most important property is what it does when it cannot decide. Making "could not read the tool call" a block-mode refusal cost one line and closes the obvious bypass.
- The Bash heuristic is honest only because it is deny-only. An allow-list for shell commands would either block ordinary work (`bundle exec rake test` names no path) or pretend to understand shell semantics.

## Challenges
None substantive.
