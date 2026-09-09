# Specification: `soft-foundry init`

## Intent
`soft-foundry init` installs the Soft Foundry control plane into an existing Git repository so the repository can run the lifecycle. It is safe on first run, idempotent on every later run, and never destroys user-owned content. `onboard` keeps its current meaning: discover model providers and repair vendor pointer files. `init` performs installation and then runs onboarding.

## Personas and authorization boundaries
- **Repository maintainer** runs `init` in a repository they own. The command acts with the maintainer's filesystem permissions only and never elevates.
- **Engineering agent** runs `init` on the maintainer's behalf in compatibility mode. The same rules apply; conflicts are reported for the maintainer to resolve, never auto-resolved.
- No network authorization is involved in installation. Provider discovery, which runs last, uses environment credentials read-only as it does today.

## Functional behavior
- **Target detection.** The target root is the Git top-level directory containing the current directory, or the directory named by `--root PATH`. A target that is not inside a Git work tree is refused unless `--allow-non-git` is passed.
- **Installed set.** The canonical `.ai/` tree packaged with the gem, minus two exceptions: `.ai/repository.yml` is installed from the pristine unassessed template, and only `README.md` is installed from `.ai/harness-evals/`. Also installed: `changes/README.md`, `docs/user/README.md` when appropriate, the `.soft-foundry/` line in `.gitignore`, and marker blocks in `AGENTS.md` and `CLAUDE.md`.
- **Ownership manifest.** The installer records the SHA-256 of every file it writes under `.ai/` in `.ai/manifest.yml`, with the Soft Foundry version. The manifest is committed with the repository. It is the sole basis for deciding whether a file is Soft Foundry-owned or user-modified.
- **Per-file outcome.** Each managed file gets exactly one status:
  - `created`: absent before, written now.
  - `updated`: present, matched its manifest hash, canonical content differs, rewritten.
  - `skipped`: present and identical to canonical content, or user-owned by rule (`changes/README.md`, `docs/user/README.md`, `.ai/repository.yml` when present). Not rewritten; modification time unchanged.
  - `conflict`: present, differs from canonical content, and either absent from the manifest or differing from its manifest hash. Left untouched unless `--force`.
  - `forced`: a conflict overwritten because `--force` was passed.
- **Pointer files.** `AGENTS.md` and `CLAUDE.md` are never replaced. Absent: created with the canonical bootstrap. Present without the Soft Foundry marker: the marker block is appended and the file is `updated`. Present with the marker: `skipped`.
- **Documentation scaffold.** `docs/user/README.md` is created only when `docs/` does not exist or `docs/user/` already exists. Otherwise the file is reported as `skipped` with the reason.
- **Options.** `--dry-run` computes and prints the full report without writing anything. `--force` resolves conflicts in favor of canonical content. `--no-onboard` skips provider discovery. `--root PATH` and `--allow-non-git` as above.
- **Order of operations.** Plan every file first; write only after the whole plan succeeds; run the control-plane check on the result; run onboarding unless disabled; print the report.
- **Report.** One line per managed file, `status  path`, followed by counts per status and the check result. Statuses are words, never only symbols.
- **Exit codes.** `0` success with no conflicts; `1` usage or environment error, including refused targets; `3` one or more conflicts remain; `4` installation failed because of Soft Foundry itself (see failure behavior). Gate and check keep `2`.
- **Runtime floor.** The gem declares Ruby 3.2 as its minimum, matching the language features the code uses.

## Accessibility
The command is non-interactive and prompts for nothing. Output is plain text: every outcome is conveyed by a word, so it is readable without color, Unicode symbols, or a terminal. `NO_COLOR` is honored trivially because no color is emitted. Long reports are line-oriented for screen readers and `grep`.

## Data and consistency
- The manifest and the installed files are written in one pass after planning; a failure during planning writes nothing.
- A failure during writing reports every file already written so the maintainer can `git checkout` or `git clean` them; the manifest is written last, so a partial install leaves no manifest and the next run treats the partial files as conflicts or skips, never as owned.
- Identical content is never rewritten, so a clean second run produces no diff and no modification-time changes.

## Failure behavior
Failures are classified and the classification determines the message:
- **Target-side** (not a Git repository, permission denied, conflicts): plain explanation and the flag or action that resolves it. Exit `1` or `3`.
- **Soft Foundry-side** (packaged canonical files missing or unreadable, control-plane check fails immediately after a clean install, an internal exception in the installer): the message names the failing component, states that the fault is in Soft Foundry rather than the target repository, and points the maintainer to the upstream repository at `https://github.com/jmscholen/soft_foundry` to fork and open a pull request or issue with the printed diagnostic. Exit `4`. The full reporting workflow is owned by the separate change `upstream-failure-reporting`; this change provides the classification and the static guidance.
- **Provider discovery failures** never fail `init`; they are reported as today by onboarding.

## Security requirements
- Every write is confined to the target root: destination paths are resolved and rejected if they escape the root or traverse a symlink that leaves it.
- Canonical files come only from the installed gem; nothing is fetched from the network during installation.
- No credentials, environment values, or machine-local state are written to the repository. `.soft-foundry/` remains gitignored.
- `--force` is the only way to overwrite user-modified content, and it never touches files outside the managed set.

## Performance and resource limits
Installation completes in under two seconds on a cold filesystem for the canonical set of about 140 files. Memory is bounded by the largest single file; files are hashed and copied one at a time.

## Infrastructure implications
None. Packaging changes only: the gemspec ships `changes/README.md`, `docs/user/README.md`, and `.ai/templates/repository.yml`, and declares Ruby 3.2.

## Observability expectations
The report and exit code are the operational surface. `soft-foundry doctor` gains a `.ai/manifest.yml` line so an incomplete or pre-manifest install is visible. `soft-foundry check` passing on a fresh install is the deterministic post-condition and is exercised in tests.

## Acceptance criteria
See `acceptance-criteria.yml`. Every criterion maps to requirement IDs in `requirements.yml` and will be bound to test names, EVAL IDs, or ATTACK IDs by later phases.
