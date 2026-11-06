# Verification Results

Commit SHA: 6af71429ad5313d70abe93aa0978a40d5a17d966
Tree: 82a4bbdc844f58ade9f4a029c9a930d72eb8727f

## Deterministic checks
Size: `full_at_verify` (`soft-foundry change size --phase verify`; no scope declared).

The change is documentation plus one hook reinstall. The implementation phase made no code change; REQ-GDH-001..003 were applied by the maintainer commit `b9f4d7c`, which is the only difference from `main` outside this record. README.md (REQ-GDH-004) is not written yet: it belongs to the documentation phase, which comes after this one, so it is not verified here.

| Check | Command | Result |
| --- | --- | --- |
| CHECK-001 | `bundle exec rake test`, provider keys and `SOFT_FOUNDRY_*` unset, run alone | pass: 902 runs, 6653 assertions, 0 failures, 0 errors, 0 skips |
| CHECK-002 | `soft-foundry check` | pass: 16 phases, 17 skills, no errors |
| CHECK-003 | `soft-foundry eval` | pass: 28 passed, 0 failed, 0 errors, 1 skipped (the live case) |
| CHECK-004 | `soft-foundry ci` | pass |
| CHECK-005 | `soft-foundry doctor` | fail (exit 2). The line this change is about passes: `guard hook (claude: installed, codex: installed; mode: block, repository policy)`. The three failing lines are machine-local and unrelated: no `.ai/manifest.yml`, no git pre-commit hook, no `.soft-foundry/runtime.yml` in this fresh checkout. See VER-001. |
| CHECK-006 | `evidence/hooks-match.rb`: a fresh `hooks install` into a throwaway directory compared with the committed files | pass: `.claude/settings.json` and `.codex/hooks.json` both equal a fresh install; PreToolUse matcher `Edit\|Write\|MultiEdit\|NotebookEdit\|Read\|Grep\|Glob\|Bash`, PostToolUse `Bash` running `guard --after` |
| CHECK-007 | the installed guard, observed live in this session | pass: Bash naming the hook settings refused; Grep and Glob into `.ai/harness-evals` refused (the matcher now covers both); Write outside the repository refused; mode block |
| CHECK-008 | `git diff --stat main...HEAD` outside `changes/`, and over `lib test exe Rakefile Gemfile gemspec .github` | pass: only `.ai/harness-evals/README.md`, `.ai/policies/enforcement.yml`, `.claude/settings.json` differ from `main`; no code, test, or CI change |
| CHECK-009 | the `enforcement.yml` header read and each claim matched to code, tests, and the live behaviour | pass: every checkable claim matches; `guard.mode: block` unchanged; "block since 0.21.0" not checked (no changelog in the repository) |

Linters, static analysis, security scanners, IaC validation and migrations: the repository's CI defines none, so none ran. `.codex/hooks.json` does not appear in the diff from `main`: the reinstall left it byte-identical, and CHECK-006 confirms it is the current install.

The checks ran from the local library (`ruby -Ilib exe/soft-foundry`), not the installed gem. The rake executable was invoked by its gem path because this machine's rbenv global is `system` and has no rake shim; the task and the test list are the Rakefile's (the transcript shows the loader's file list).

## Requirements not verifiable in this phase
- **REQ-GDH-003** (`.ai/harness-evals/README.md`): `.ai/harness-evals/**` is in this skill's `deny_read`, and in review's and judgment's. `git diff --stat main...HEAD` shows the file gained six lines in `b9f4d7c`; its content is checked by nobody in the lifecycle and falls to the maintainer at merge. See VER-002.
- **REQ-GDH-004** (README.md): not yet written; the documentation phase follows. The gate's staleness check does not cover `DOCS`, so that edit will not stale this evidence; evaluation and review must read the README when it exists. See VER-003.

## Failures
CHECK-005 (`soft-foundry doctor`) exits 2 on three machine-local checks that predate and are unrelated to this change; the guard-hook line, the one REQ-GDH-001 bears on, passes. Recorded as VER-001, not blocking.

No other failures.

## Evidence
Under `evidence/`, listed with digests in `evidence/manifest.yml`. No check has a `red_commit`: a documentation change with no test first. The specify phase is waived, so no check names acceptance criteria. The guard's refusals in `guard-live.txt` are the hook's replies copied verbatim; no payload contains hidden characters.

Evidence generated for a different implementation commit is stale.
