# Implementation Plan

## Approach
Add a pure planning core, `SoftFoundry::Installer`, that computes a per-file action list from three inputs: the packaged canonical source, the target work tree, and the ownership manifest. Writing is a separate step that consumes the plan, so `--dry-run` and the plan-before-write requirement (REQ-010) fall out of the structure. Failure classification is expressed as two exception classes so the CLI can map them to exit codes and messages without inspecting strings.

The ten specification gaps from `03-threat-model/mitigations.md` all tighten behavior and none contradict a locked acceptance criterion, so this plan adopts them as design constraints (DC-1 to DC-10 below). They are recorded here rather than in the specification because planning may not edit `02-specification`; the learning phase should propose a formal requirement-amendment transition, which the workflow currently lacks.

## Design constraints adopted from the threat model
- **DC-1** A managed file with uncommitted modifications is always `conflict` (reason `uncommitted`), even under `--force`. `--force` combined with `--allow-non-git` is refused. (MIT-004, MIT-006)
- **DC-2** `--force` applies only to `conflict` statuses on files in the packaged `.ai/` set. Pointer files, `.ai/repository.yml`, `changes/README.md`, `docs/user/README.md`, and `.gitignore` are never forced. (MIT-006)
- **DC-3** A symlink or non-regular file at or above any managed destination, inside or outside the root, is a target-side refusal before anything is written. (MIT-001, MIT-014)
- **DC-4** The manifest is schema-validated on load; entries outside the packaged set are reported and ignored; `init` never deletes or renames a file. (MIT-005)
- **DC-5** A pointer file is `skipped` only when the full canonical block sits between begin and end markers; a bare marker without the block is `conflict`. (MIT-009)
- **DC-6** `--root` must resolve to the Git top-level via `git -C ROOT rev-parse --show-toplevel` unless `--allow-non-git`; `GIT_DIR` and `GIT_WORK_TREE` are cleared for that call; the report's first line prints the resolved absolute root. (MIT-008)
- **DC-7** "Clean install" for classification means no `conflict` and no pre-existing non-identical `.ai/` file. Diagnostics contain no environment values, only repository-relative paths, and no hostnames. (MIT-012)
- **DC-8** `.gitignore` is `skipped` only when `git check-ignore -q .soft-foundry/` succeeds; textual presence without effect is `conflict`. Under `--allow-non-git`, textual presence is the fallback. (MIT-011)
- **DC-9** `soft-foundry check` reports an error when a `repository.yml` override empties a required path group. This is in scope because it is a one-line addition to `Check` and closes THREAT-010 for every repository, not only fresh installs. (MIT-010)
- **DC-10** `init` takes an exclusive lock at `.soft-foundry/init.lock` and refuses to run concurrently. (MIT-007)

## Application changes
| Step | File | Change |
| --- | --- | --- |
| 1 | `lib/soft_foundry/errors.rb` | `Error`, `TargetError` (exit 1), `ConflictsRemain` (exit 3), `InternalError` (exit 4, carries `component` and `diagnostic`). |
| 1 | `soft_foundry.gemspec` | `required_ruby_version >= 3.2`; add `changes/README.md`, `docs/user/README.md` to files. |
| 1 | `.ai/templates/repository.yml` | Pristine unassessed profile, copied from the pre-discovery version of `.ai/repository.yml`. |
| 2 | `lib/soft_foundry/manifest.rb` | Load, validate (`version`, `soft_foundry_version`, `files` of relative path to 64-hex SHA-256), diff, and write `.ai/manifest.yml`. Unknown entries collected as warnings. `YAML.safe_load` with `aliases: false`. |
| 3 | `lib/soft_foundry/installer/source.rb` | Enumerates the packaged canonical set from the gem root: `.ai/**` minus `harness-evals/*` except its README, minus `repository.yml` (replaced by `templates/repository.yml`), minus `manifest.yml`; plus `changes/README.md`; plus `docs/user/README.md`. Rejects any packaged entry that is a symlink or whose relative path contains `..` (MIT-002). |
| 4 | `lib/soft_foundry/installer.rb` | `plan` returns `Action(path, status, reason, bytes)`. Status rules per REQ-005/006, DC-1 to DC-5. Uses `Git#dirty_paths` for DC-1 and `File.lstat` walks for DC-3. Pure: no writes. |
| 5 | `lib/soft_foundry/installer.rb` | `apply(plan)` takes the lock (DC-10), writes files one at a time with `File.open(..., "wb")` into a temp file then `rename` for atomic replacement, records written paths for the partial-failure report (REQ-010), writes the manifest last (REQ-004). |
| 6 | `lib/soft_foundry/agent_files.rb` | Add `AGENTS_BEGIN`/`AGENTS_END` markers and a full-block check for both pointer files (DC-5). Return `:created`, `:updated`, `:skipped`, `:conflict`. Refuse symlinked pointer files (DC-3). Keep `CLAUDE_MARKER` for backward compatibility by treating the legacy single marker plus body as the full block. |
| 6 | `lib/soft_foundry/onboarding.rb` | `ensure_local_ignore` moves to the installer as a managed action with `git check-ignore` (DC-8); onboarding calls the installer's ignore action so `onboard` alone still works. |
| 7 | `lib/soft_foundry/cli.rb` | Separate `init` from `onboard`. Parse `--dry-run`, `--force`, `--no-onboard`, `--root PATH`, `--allow-non-git`. Print resolved root, one `status  path` line per action, counts, check result. Map exceptions to exit codes; on `InternalError` print the upstream guidance with the repository URL read from the gemspec metadata (`Gem.loaded_specs` with a constant fallback). Sanitize provider model ids to printable ASCII in `models` and onboarding output (MIT-015). |
| 8 | `lib/soft_foundry/cli.rb`, `lib/soft_foundry/check.rb` | `doctor` gains `.ai/manifest.yml`; `check` gains the empty-required-group error (DC-9). `check` runs after install and its failure on a clean install raises `InternalError` (REQ-011, DC-7). |
| 9 | `README.md`, `docs/user/README.md`, `lib/soft_foundry/version.rb` | Document `init`, options, statuses, exit codes, and upgrade notes; bump to 0.2.0. |

Steps 1 to 5 have no user-visible effect until step 7 wires them in, so each can land with its tests before the CLI changes.

## Database changes
N/A.

## Infrastructure changes
N/A. CI already runs `rake test` and `rake ci`.

## Test strategy
See `testing.md`. Every acceptance criterion maps to a named test, and each mitigation with `attack_case_required: true` gets a unit-level test so attack can focus on end-to-end attempts.

## Rollout
See `rollout.md`.

## Rollback
See `rollback.md`.

## Risks
- **Scope growth.** Ten adopted constraints roughly double the installer's rule count. Mitigation: the plan is pure and table-driven, and every rule has a test; steps 1 to 5 land before any CLI change.
- **Ruby floor.** Raising to 3.2 excludes 3.1 users. The code already fails on 3.1 at load time, so this is a correctness fix, but the README must say so.
- **Line-ending drift.** The manifest is byte-exact, so `core.autocrlf` on Windows can turn every file into a conflict. Mitigation: document; a normalization option is a follow-up, not this change.
- **Legacy `CLAUDE.md` blocks.** Repositories onboarded with the current single-marker block must be recognized as complete, or every existing user sees a conflict. Covered by a dedicated test.
- **`git check-ignore` availability.** Requires git 1.8.5 or later; treated as satisfied and noted in the README.
- **Self-install.** Running `init` inside the Soft Foundry repository itself is not meaningful and is not supported; `doctor` remains the self-check.
