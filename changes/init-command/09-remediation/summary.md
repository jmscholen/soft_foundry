# Remediation (second run: attack findings)

The first remediation run (evaluation findings, commit 420acdc) is archived under `previous/420acdc5f35d/`.

## Finding references
ATTACK-F-001 (critical) through ATTACK-F-012 from `08-attack/handoff.yml`, mapped to violations V1 to V7 in `08-attack/results.md`.

## Root cause
- **V1 temp-sibling symlink (critical).** The atomic write created `<path>.soft-foundry-tmp` with a following open, so a committed symlink at that sibling redirected the write anywhere. The path guard never considered the sibling.
- **V2 `.soft-foundry` symlink and hardlink.** The lock file and `runtime.yml` were opened with following semantics and no guard on the directory.
- **V3 git-ignored edits bypass.** `git status --porcelain` omits ignored files, so an uncommitted edit under an ignored path was invisible to the uncommitted-edit rule; `--allow-non-git` inside a repository skipped the rule entirely.
- **V4 redirected path-group overrides.** `repository.yml` could override `HARNESS_EVALS` and `CONTROL_PLANE`, and could point `APP` at nothing, blinding staleness and harness-eval denial; `check` only detected empty groups.
- **V5 misclassification.** "Clean install" ignored pre-existing or extra files under `.ai/`, so user-caused check failures became exit 4; several filesystem conditions raised raw exceptions; the diagnostic sanitizer used the working directory instead of the resolved root.
- **V6 FIFO hangs.** The manifest and `.gitignore` were read before their file type was checked, and `git status` ran before any guard.
- **V7 raw provider strings.** Only model ids were sanitized, without length limits, and `models` printed stored values raw.
- False conflicts: block detection required a leading newline and exact LF endings.

## Changes made
- `lib/soft_foundry/safe_write.rb` (new): every write opens the temp sibling with `O_EXCL|O_NOFOLLOW`, refuses an existing sibling, refuses symlinked or non-regular destinations and non-directory parents.
- `lib/soft_foundry/installer.rb`: guards every managed path, the temp sibling, and `.soft-foundry` before any read of the target; dirty detection covers ignored paths and applies whenever a repository exists; `clean` requires no pre-existing or extra `.ai/` files; lock opened with `O_NOFOLLOW`.
- `lib/soft_foundry/git.rb`: `dirty_paths` includes ignored files and directories.
- `lib/soft_foundry/onboarding.rb`: `runtime.yml` written through `SafeWrite` with a directory guard.
- `lib/soft_foundry/manifest.rb`: refuses non-regular files before reading.
- `lib/soft_foundry/control_plane.rb`, `lib/soft_foundry/check.rb`: `CONTROL_PLANE` and `HARNESS_EVALS` cannot be overridden (defaults kept, error reported); an override for a required group that matches no files while the defaults do is an error.
- `lib/soft_foundry/cli.rb`: sanitizer uses the resolved root and tolerates a missing home; post-install check failures are caught; the internal-failure message states whether files were written; refuses `/` as root; `models` sanitizes output.
- `lib/soft_foundry/provider.rb`: sanitizes and truncates ids and errors to 200 characters.
- `lib/soft_foundry/agent_files.rb`: block detection ignores the leading newline and CRLF.
- Tests: 16 new, one adjusted for the protected-group rule. 90 runs, 805 assertions locally.
- Not changed: MIT-008 home-directory root warning, MIT-014 memory bound for very large files, local git excludes suppressing the `.gitignore` line, and `docs` symlink refusal. Recorded as residual for review.

## Evidence invalidated
- `06-verification` (a733f84 run) and `07-evaluation` (06a4830 run): archived under `previous/`, handoffs reset to `pending`.
- `08-attack` (afbad2d run): archived under `previous/afbad2d5a9c1/`; stays `blocked` until rerun.

## Required reruns
Verification, then evaluation and attack (attack may run concurrently with evaluation and is gated on it at closing).
