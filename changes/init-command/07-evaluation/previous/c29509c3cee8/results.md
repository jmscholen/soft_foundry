# Evaluation Results

Commit SHA: c29509c3cee8e74dfb4266906f47a59ab82a90e6 (branch `change/init-command`)

Rerun after remediation. The previous run at `6a41afd123ca` was blocked on EVAL-014 and is archived under `previous/6a41afd123ca/` (untouched). Runtime: ruby 3.3.1 (`/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby`), Soft Foundry run from source at this commit. Sixteen journeys (fifteen re-executed with unchanged expected outcomes plus the new EVAL-016), four personas, fresh scratch repositories; every command, output, exit code, and post-state is in the transcripts under `evidence/`, produced by the scripts under `evidence/scripts/`. No file outside `changes/init-command/07-evaluation/` was modified; the worktree carried only the pre-existing `metadata.yml` change (`current_phase: evaluate`).

## Journey outcomes
| Journey | Persona | Criteria | Result | Evidence |
| --- | --- | --- | --- | --- |
| EVAL-001 first install, commit, re-run | (a) | AC-001, AC-003, AC-010 | pass (17/17, mtime stretch included) | `evidence/EVAL-001-first-install-idempotent.log` |
| EVAL-002 existing AGENTS.md and CLAUDE.md preserved | (b) | AC-004, AC-005 | pass (11/11) | `evidence/EVAL-002-pointer-files-preserved.log` |
| EVAL-003 dry-run preview then real run | (c) | AC-012 | pass (7/7) | `evidence/EVAL-003-dry-run-then-real.log` |
| EVAL-004 committed edit: conflict with guidance, `updated` sibling, `--force` | (a)/(b) | AC-006, AC-007, AC-003 | pass (15/15) | `evidence/EVAL-004-conflict-then-force.log` |
| EVAL-005 uncommitted edit stays conflict even with `--force` | (b) | AC-006 | pass (9/9) | `evidence/EVAL-005-uncommitted-edit.log` |
| EVAL-006 non-git refusal, `--allow-non-git`, `--force` refused with it | (c) | AC-002 | pass (5/5) | `evidence/EVAL-006-non-git.log` |
| EVAL-007 docs/ without docs/user/ | (a) | AC-011 | pass (4/4) | `evidence/EVAL-007-docs-without-user.log` |
| EVAL-008 .gitignore already effective; append control | (b) | AC-009 | pass (4/4) | `evidence/EVAL-008-gitignore.log` |
| EVAL-009 `--root` subdirectory refusal; root printed | (c) | AC-001, AC-002 | pass (6/6) | `evidence/EVAL-009-root-option.log` |
| EVAL-010 onboarding with no provider keys, env var named | (a) | AC-015 | pass (9/9) | `evidence/EVAL-010-no-provider-keys.log` |
| EVAL-011 ASCII-stripped status parsing incl. guidance lines | (c) | AC-016 | pass (8/8) | `evidence/EVAL-011-ascii-status-words.log` |
| EVAL-012 broken package: exit 4 and upstream guidance | (a) | AC-013 | pass (10/10) | `evidence/EVAL-012-internal-failure.log` |
| EVAL-013 hand-copied .ai/ without manifest | (d) | AC-008, AC-010, AC-007 | pass (13/13) | `evidence/EVAL-013-hand-copied-ai.log` |
| EVAL-014 CLI scripting surface | (c) | specification "Exit codes" | pass (9/9; was fail at 6a41afd) | `evidence/EVAL-014-cli-surface.log` |
| EVAL-015 .ai symlinked outside the repository | (b) | AC-014 | pass (4/4) | `evidence/EVAL-015-symlinked-ai.log` |
| EVAL-016 dry-run preview of a conflicting upgrade (new) | (c) | AC-012, AC-006 | pass (4/4) | `evidence/EVAL-016-dry-run-conflict-preview.log` |

Acceptance criteria coverage: AC-001 through AC-016 each have at least one passing journey. AC-017 (gem packaging) was proven by verification check 9 and is not a user journey.

## Remediated behaviours, observed from the user's side
- **EVAL-F-001 (was blocking).** `soft-foundry init --root` with no value now prints exactly `soft-foundry: --root requires a value` on stderr and exits 1; no "defect in Soft Foundry" text, no diagnostic block, no fork guidance, nothing written (EVAL-014 step 5). The genuine Soft Foundry-side path is unchanged and still exits 4 with the upstream guidance (EVAL-012).
- **EVAL-F-003 / EVAL-F-004.** Every conflict run now ends with `conflicts: <path>[, <path>]` and `next: compare with `git diff`, keep your version, or commit it and rerun with --force to take the canonical version (uncommitted edits are never overwritten)` after the `summary:` line. Observed on a committed-edit upgrade (EVAL-004), an uncommitted edit with and without `--force` (EVAL-005), a hand-copied tree with two conflicts listed in one line (EVAL-013), a plain rerun (EVAL-011 run 2), and a `--dry-run` preview (EVAL-016). Runs with no conflicts print neither line (EVAL-004 force run, EVAL-013 force run). Both lines survive non-ASCII stripping and are not miscounted by a first-word parser (EVAL-011).
- **EVAL-F-005.** Onboarding prints `openai     not configured (set OPENAI_API_KEY)`, `anthropic  not configured (set ANTHROPIC_API_KEY)`, `xai        not configured (set XAI_API_KEY)` (EVAL-010); `runtime.yml` still records only `configured: false` and no key values.

Other confirmations unchanged from the previous run: idempotent to the modification time (EVAL-001), pointer prose preserved byte for byte (EVAL-002), `updated` upgrade path exercised end to end (EVAL-004, VER-001 evidence half), `--force` never touches `.ai/repository.yml` and is refused with `--allow-non-git` (EVAL-013, EVAL-006), diagnostic free of secrets and absolute paths (EVAL-012).

## Failures
None. Every assertion in all sixteen journeys passed. One transcript (EVAL-013) was regenerated once after fixing a quoting defect in a newly added harness assertion (an unexpanded `$LOG` inside a command substitution, the same class of harness bug fixed in the previous run); the expected outcome was not changed and the transcript already showed the behaviour the assertion checks. The scripts under `evidence/scripts/` are the fixed versions.

## Report usability
The terminal report is the product's whole UI. Assessed on its own terms after remediation:

- **Status words and reasons.** Unchanged and adequate: `created`, `skipped`, `conflict`, `forced` are self-explanatory; `updated` is disambiguated by its reason (`block appended`, `appended .soft-foundry/`, `owned by manifest`). Conflict reasons (`differs from manifest hash`, `not in manifest`, `uncommitted modifications`) remain installer-centric, but the new `next:` line now supplies the action, which removes most of the previous cost.
- **Conflict guidance.** `conflicts:` gives the exact paths in one line; `next:` names `git diff`, keeping the file, or committing and rerunning with `--force`, and says uncommitted edits are never overwritten. A maintainer can act from the last three lines alone. Two residual observations: the `next:` line is generic (on an uncommitted-edit conflict the operative instruction, "commit it first", is only implied by the parenthetical), and it is a single 150-character sentence, which wraps on narrow terminals and is long for a screen reader.
- **Summary line and ordering.** `summary:` still comes after up to 171 file lines, but `conflicts:`/`next:` after it mean the decision-bearing information is now the last three lines of the report, which is a reasonable convention for a CLI. `check: ok` still immediately precedes an exit-3 summary on conflict runs and can read as success to a skimming reader; the `conflicts:` line below it mitigates this. The MIT-004(b) `git diff` hint after `updated`/`forced` on non-conflict runs is still absent (VER-006 carried).
- **Resolved root.** `root: <absolute path>` remains the first line of every report including `--dry-run`; refusals name the path and the resolving flag in one sentence.
- **Onboarding.** `not configured (set OPENAI_API_KEY)` tells the maintainer exactly what to do.
- **Help.** `soft-foundry init --help` and `init -h` are still refused as `unknown option(s)` with exit 1; `soft-foundry help` prints the global usage but exits 1. The option list exists only in the top-level usage. Remediation deliberately left this for review (REM-002 / VER-009).
- **Lock file.** `.soft-foundry/init.lock` (0 bytes) is left in the gitignored directory after every run (VER-010); it does not affect idempotence or `git status`.

## Accessibility observations
- Keyboard-only interaction: not applicable. The command is non-interactive and never reads input; every journey, including refusals, conflicts, dry runs, and the internal failure, returned without a prompt.
- Screen-reader readability: every outcome is a word. EVAL-011 captured raw bytes of three runs covering all five statuses plus the new guidance lines and found zero non-ASCII bytes and no escape sequences; after stripping to printable ASCII every status and the `conflicts:`/`next:` prefixes were still identifiable and the parsed counts matched the `summary:` line. Fixed prefixes (`root:`, `mode:`, `check:`, `summary:`, `conflicts:`, `next:`, `warning:`, `soft-foundry:`) can be jumped to.
- Improvement since the previous run: a screen-reader user no longer has to search 170 `skipped` lines for a single `conflict`; the path is repeated in the `conflicts:` line after the summary.
- Residual: the `next:` sentence length (finding EVAL-F-003) and `check: ok` preceding an exit-3 summary (EVAL-F-004).

## Findings
| ID | Severity | Summary |
| --- | --- | --- |
| EVAL-F-001 | info | Resolved. `init --root` with no value now exits 1 with the single line `soft-foundry: --root requires a value` and no defect guidance (EVAL-014); the blocking failure of the previous run is closed. |
| EVAL-F-002 | minor | Carried. `init --help` and `init -h` are refused as `unknown option(s)` with exit 1; there is no per-command help, and `soft-foundry help` prints the global usage but exits 1. Left for review by remediation (REM-002, VER-009). |
| EVAL-F-003 | minor | The new `next:` guidance is a single generic 150-character sentence; on an uncommitted-edit conflict the operative step (commit first) is only implied by the parenthetical, and the line wraps on narrow terminals. `conflicts:`/`next:` are otherwise correct on every conflict run and absent on every clean run. |
| EVAL-F-004 | minor | `check: ok` still immediately precedes an exit-3 `summary:` on conflict runs and can read as success; the `conflicts:` line below it mitigates this. The MIT-004(b) `git diff` hint after `updated`/`forced` on non-conflict runs is still absent (VER-006). |
| EVAL-F-005 | info | Resolved. Onboarding prints `not configured (set OPENAI_API_KEY)` style lines for all three providers (EVAL-010); `runtime.yml` carries no key values. |
| EVAL-F-006 | info | Carried. Conflict reasons presume knowledge of `.ai/manifest.yml`; user documentation should define the manifest, the five statuses, the `conflicts:`/`next:` lines, exit codes 0/1/3/4, and the `.soft-foundry/init.lock` file (VER-010). |
| EVAL-F-007 | info | Carried. The `updated` upgrade path for an owned `.ai/` file has end-to-end evidence (EVAL-004); the automated-test half of VER-001 remains open. |
| EVAL-F-008 | info | Every behaviour in AC-001..AC-016 matched the specification from the user's side across four personas and sixteen journeys at c29509c, including the three remediated report behaviours; no journey failed. |
