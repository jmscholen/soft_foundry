# Implementation Log

## Changes made
Steps follow `04-plan/implementation.md`.

1. `lib/soft_foundry/errors.rb`: `Error`, `TargetError`, `InternalError` with `component` and `diagnostic`. Gemspec now requires Ruby 3.2 and packages `changes/README.md` and `docs/user/README.md`. `.ai/templates/repository.yml` added as the pristine unassessed profile (copied from the pre-discovery `.ai/repository.yml`). Version bumped to 0.2.0.
2. `lib/soft_foundry/manifest.rb`: load with `aliases: false`, schema validation (version, relative `.ai/` paths, 64-hex hashes), symlink refusal, `owned?`, sorted YAML output.
3. `lib/soft_foundry/installer/source.rb`: packaged set enumeration with the two exceptions, scaffolding, required-file and symlink/traversal checks raising `InternalError`, and `agents_interior` extracted from between the markers in the packaged `AGENTS.md`.
4. `lib/soft_foundry/installer.rb` `plan`: one `Action` per managed file with the five statuses, DC-1 uncommitted rule, DC-2 force scope, DC-3 ancestor symlink and non-regular guard, DC-4 manifest warnings and never-delete, DC-8 `git check-ignore`. `clean` flag for DC-7.
5. `Installer#apply`: DC-10 lock at `.soft-foundry/init.lock`, temp-file-and-rename writes, partial-failure message listing written files, manifest written last and only when changed.
6. `lib/soft_foundry/agent_files.rb`: begin/end markers, full-block check (DC-5), legacy 0.1.0 `CLAUDE.md` block recognized, symlink refusal. `AGENTS.md` in this repository wrapped in the markers so the installer extracts the canonical block from the packaged file. `lib/soft_foundry/onboarding.rb`: adapter repair now uses the installer's adapter actions; `providers_only:` for `init`.
7. `lib/soft_foundry/cli.rb`: `init` separated from `onboard`; `--dry-run`, `--force`, `--no-onboard`, `--root`, `--allow-non-git`; root resolution via `git rev-parse --show-toplevel` with `GIT_DIR`/`GIT_WORK_TREE` cleared (DC-6); report with resolved root, one status word per file, counts, check result; exit codes 0/1/3/4; `InternalError` prints sanitized upstream guidance with the repository URL from gem metadata. `lib/soft_foundry/provider.rb`: model ids and errors sanitized to printable ASCII (MIT-015).
8. `doctor` reports `.ai/manifest.yml`; `check` errors when a required path group resolves to nothing (DC-9).
9. Documentation: deferred, see `deviations.md`.

## Decisions
See `decisions.md`.

## Deviations from plan
See `deviations.md`.

## Challenges
No substantive blockers. Two permission-boundary questions arose and are recorded as deviations rather than challenges.

## Verification performed locally
`ruby -Ilib -Itest` over `test/*_test.rb`: 67 runs, 740 assertions, 0 failures. `soft-foundry check` passes. `soft-foundry init --dry-run --no-onboard` on this repository reports every packaged file `skipped (identical)` and only `CLAUDE.md` `created`. These are implementation observations, not verification evidence; the verification phase reruns them.
