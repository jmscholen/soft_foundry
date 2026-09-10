# Evaluation Results

Commit SHA: a7b9df1bd6ac5c50346515d04a9a4a3853b86c6d (branch `change/init-command`)

Fourth run, by a fresh-context agent under evaluation permissions, after the second remediation (attack findings V1..V7). The first run at `6a41afd123ca` was blocked on EVAL-014; the second at `c29509c3cee8` passed; the third at `a733f84086d0` passed after an unrelated harness fix. All three are archived, unmodified, under `previous/6a41afd123ca/`, `previous/c29509c3cee8/`, and `previous/a733f84086d0/`. `git diff --stat a733f84086d0..a7b9df1 -- lib exe test soft_foundry.gemspec .ai` shows the remediation changed `lib/soft_foundry/{safe_write.rb (new),installer.rb,git.rb,onboarding.rb,manifest.rb,control_plane.rb,check.rb,cli.rb,provider.rb,agent_files.rb}`, so no outcome from the third run was assumed to still hold; all nineteen journeys below (the sixteen from the third run plus three new legitimate-use journeys) were executed fresh against HEAD and every command, output, exit code, and post-state is in the transcripts under `evidence/`, each of which records `HEAD a7b9df1bd6ac5c50346515d04a9a4a3853b86c6d` in its header.

At the start of this run the top-level `evaluation-plan.md`, `journeys.yml`, `results.md`, and 18 evidence files still held the archived third run's content verbatim (left over from before the handoff reset; only `handoff.yml` had been reset to `pending`). Everything under this directory except `previous/` was regenerated from scratch for HEAD `a7b9df1` in this run. No file outside `changes/init-command/07-evaluation/` was modified; the worktree carried only the pre-existing `metadata.yml` phase-bookkeeping change and (concurrently, and not read or waited on) the attack phase's own files under `08-attack/`.

Runtime: ruby 3.3.1 (`/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby`, resolved from the asdf shim `which ruby` reports at the repository root, then invoked by its concrete absolute path so a scratch directory's asdf resolution cannot substitute a different Ruby), Soft Foundry run from source at this commit. 19 journeys, 157 assertions, all passing, five personas (including a new teammate/CI-clone persona), fresh scratch Git repositories per journey.

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
| EVAL-010 onboarding with no provider keys, env var named | (a) | AC-015 | pass (11/11, incl. legitimate-use `.soft-foundry/` checks) | `evidence/EVAL-010-no-provider-keys.log` |
| EVAL-011 ASCII-stripped status parsing incl. guidance lines | (c) | AC-016 | pass (8/8) | `evidence/EVAL-011-ascii-status-words.log` |
| EVAL-012 broken package: exit 4 and upstream guidance | (a) | AC-013 | pass (10/10) | `evidence/EVAL-012-internal-failure.log` |
| EVAL-013 hand-copied .ai/ without manifest | (d) | AC-008, AC-010, AC-007 | pass (13/13) | `evidence/EVAL-013-hand-copied-ai.log` |
| EVAL-014 CLI scripting surface | (c) | specification "Exit codes" | pass (9/9) | `evidence/EVAL-014-cli-surface.log` |
| EVAL-015 .ai symlinked outside the repository | (b) | AC-014 | pass (4/4) | `evidence/EVAL-015-symlinked-ai.log` |
| EVAL-016 dry-run preview of a conflicting upgrade | (c) | AC-012, AC-006 | pass (4/4) | `evidence/EVAL-016-dry-run-conflict-preview.log` |
| EVAL-017 (new) gitignored non-.ai build artifact is inert to init | (b) | AC-006 | pass (7/7) | `evidence/EVAL-017-gitignored-build-artifact.log` |
| EVAL-018 (new) reasonable non-empty repository.yml path override works normally | (b) | none (outside AC-001..017; control-plane behaviour) | pass (6/6) | `evidence/EVAL-018-repository-yml-override.log` |
| EVAL-019 (new) pointer-file block detection survives a fresh git clone | (e) | AC-003, AC-004, AC-005 | pass (7/7) | `evidence/EVAL-019-fresh-clone-block-detection.log` |

Acceptance criteria coverage: AC-001 through AC-016 each have at least one passing journey. AC-017 (gem packaging) was proven by verification check 8 and is not a user journey.

## New legitimate-use journeys (V1..V7 remediation, seen from a maintainer, not an attacker)
The attack phase (`08-attack/`) exercises these same code paths adversarially and ran concurrently with this phase; the three journeys below instead ask whether the hardening added by the second remediation gets in the way of ordinary, non-hostile use, per this run's instructions.
- **EVAL-017.** A `.gitignore`d, untracked build artifact (`tmp/cache`, outside `.ai/`) sits in the repository the whole time. The V3 fix broadened `git.rb#dirty_paths` to include ignored paths, but that broadening is scoped correctly: the artifact is never listed as a managed action, never appears in a `conflicts:` line, and does not stop the uncommitted-edit conflict rule from correctly firing on (and only on) the `.ai/` file a maintainer actually edited without committing.
- **EVAL-018.** A maintainer with `src/`/`spec/`/`infra/` instead of the conventional layout can still give `.ai/repository.yml` a non-empty `paths:` override for `APP`/`TESTS`/`INFRA`; `soft-foundry check` reports no error and `init` stays idempotent. The same journey's control step confirms the V4 fix still rejects an override of the protected `HARNESS_EVALS` group (`exit 2`, naming the group) in the same file, so the anti-abuse hardening and the legitimate customization path coexist without either one weakening the other.
- **EVAL-019.** After `init` writes and a maintainer commits `AGENTS.md`/`CLAUDE.md`, a second maintainer (or CI runner) who only has a fresh `git clone` — not the original working tree — still gets `skipped (block present)` on both files when they run `init`, never a false `conflict`. This confirms the `agent_files.rb` block-detection normalization (the fix behind the ATTACK-012 false-conflict family) generalizes past the one working tree it was written in.

None of the three surfaced a regression; all are `pass`.

## Remediated behaviours, observed again from the user's side at this commit
- **`init --root` with no value (was EVAL-F-001, blocking at the first run).** Still prints exactly `soft-foundry: --root requires a value` on stderr and exits 1; no "defect in Soft Foundry" text, no diagnostic block, no fork guidance, nothing written (EVAL-014 step 5). The genuine Soft Foundry-side internal failure path is unchanged and still exits 4 with the upstream guidance (EVAL-012).
- **Conflict guidance (`conflicts:`/`next:`).** Every conflict run still ends with `conflicts: <path>[, <path>]` and `next: compare with \`git diff\`, keep your version, or commit it and rerun with --force to take the canonical version (uncommitted edits are never overwritten)` after the `summary:` line: a committed-edit upgrade (EVAL-004), an uncommitted edit with and without `--force` (EVAL-005), a hand-copied tree with two conflicts listed in one line (EVAL-013), a plain rerun and the new ignored-artifact rerun (EVAL-011, EVAL-017), and a `--dry-run` preview (EVAL-016). Runs with no conflicts print neither line (EVAL-004 force run, EVAL-013 force run, EVAL-018). Both lines survive non-ASCII stripping and are not miscounted by a first-word status parser (EVAL-011).
- **Onboarding provider guidance.** `openai     not configured (set OPENAI_API_KEY)`, `anthropic  not configured (set ANTHROPIC_API_KEY)`, `xai        not configured (set XAI_API_KEY)` (EVAL-010); `runtime.yml` still records only `configured: false` and no key values, and a second `onboard` run against the same, still-plain `.soft-foundry/` directory behaves the same way.
- **Diagnostic sanitization (V5).** The internal-failure message for a broken package states the fault is Soft Foundry's, names the missing file and the `package` component, points upstream with `gh repo fork` guidance, and leaks no secret value, no absolute target path, no absolute source path, and no home-directory path (EVAL-012).

Other confirmations unchanged from the third run: idempotent to the modification time (EVAL-001), pointer prose preserved byte for byte (EVAL-002), `updated` upgrade path exercised end to end (EVAL-004), `--force` never touches `.ai/repository.yml` and is refused combined with `--allow-non-git` (EVAL-013, EVAL-006).

## Failures
None. Every assertion in all nineteen journeys passed on the first execution at this commit.

## Report usability
The terminal report is the product's whole UI. Assessed on its own terms at this commit:
- **Status words and reasons.** `created`, `skipped`, `conflict`, `forced` are self-explanatory; `updated` is disambiguated by its reason (`block appended`, `appended .soft-foundry/`, `owned by manifest`). Conflict reasons (`differs from manifest hash`, `not in manifest`, `uncommitted modifications`) remain installer-centric, but the `next:` line supplies the action.
- **Conflict guidance.** `conflicts:` gives the exact paths in one line; `next:` names `git diff`, keeping the file, or committing and rerunning with `--force`, and says uncommitted edits are never overwritten. Two residual observations, unchanged since the third run: the `next:` line is generic (on an uncommitted-edit conflict the operative instruction, "commit it first", is only implied by the parenthetical), and it is a single long sentence that wraps on narrow terminals.
- **Summary line and ordering.** `summary:` still comes before up to 171 file lines are already printed and `conflicts:`/`next:` after it, so the decision-bearing information is the last lines of the report. `check: ok` still immediately precedes an exit-3 `summary:` on conflict runs and can read as success to a skimming reader; the `conflicts:` line below it mitigates this. The `git diff` hint after `updated`/`forced` on non-conflict runs is still absent.
- **Resolved root.** `root: <absolute path>` remains the first line of every report including `--dry-run`; refusals name the path and the resolving flag in one sentence. On the internal-failure path (EVAL-012) `root:` is never printed because the packaged-file check runs before that line, which is consistent with "nothing was changed" but means an agent parsing for `root:` first should not assume its absence means the target was misidentified.
- **Onboarding.** `not configured (set OPENAI_API_KEY)` tells the maintainer exactly what to do.
- **Help.** `soft-foundry init --help` and `init -h` are still refused as `unknown option(s)` with exit 1; `soft-foundry help` prints the global usage but exits 1. The option list exists only in the top-level usage.
- **Lock file.** `.soft-foundry/init.lock` (0 bytes) is left in the gitignored directory after every run; it does not affect idempotence or `git status`.
- **Legitimate-use additions this run.** A reasonable `repository.yml` path override produces no extra noise: `check` prints the same success line as before, and `init` prints the same `skipped (repository state is owned by this repository)` line it always has for `repository.yml` (EVAL-018). A fresh clone's report is indistinguishable from the original working tree's second run (EVAL-019).

## Accessibility observations
- Keyboard-only interaction: not applicable. The command is non-interactive and never reads input; every journey, including refusals, conflicts, dry runs, the internal failure, and the new legitimate-use journeys, returned without a prompt.
- Screen-reader readability: every outcome is a word, never a symbol-only signal. EVAL-011 captured raw bytes of three runs covering all five statuses plus the guidance lines and found zero non-ASCII bytes and no escape sequences; after stripping to printable ASCII every status and the `conflicts:`/`next:` prefixes were still identifiable and the parsed counts matched the `summary:` line. Fixed prefixes (`root:`, `mode:`, `check:`, `summary:`, `conflicts:`, `next:`, `warning:`, `soft-foundry:`) can be jumped to.
- Residual, unchanged since the third run: the `next:` sentence length and `check: ok` preceding an exit-3 summary.

## Findings
| ID | Severity | Summary |
| --- | --- | --- |
| EVAL-F-001 | info | Resolved and reconfirmed at HEAD. `init --root` with no value exits 1 with the single line `soft-foundry: --root requires a value` and no defect guidance (EVAL-014). |
| EVAL-F-002 | minor | Carried. `init --help` and `init -h` are refused as `unknown option(s)` with exit 1; there is no per-command help, and `soft-foundry help` prints the global usage but exits 1. Deliberately left unremediated per `09-remediation/summary.md` (REM-005) and verification (VER-009). |
| EVAL-F-003 | minor | Carried. The `next:` guidance is a single generic sentence; on an uncommitted-edit conflict the operative step (commit first) is only implied by the parenthetical, and the line wraps on narrow terminals. `conflicts:`/`next:` are otherwise correct on every conflict run (including the two new ones, EVAL-017 and EVAL-018's control step) and absent on every clean run. |
| EVAL-F-004 | minor | Carried. `check: ok` still immediately precedes an exit-3 `summary:` on conflict runs and can read as success; the `conflicts:` line below it mitigates this. The `git diff` hint after `updated`/`forced` on non-conflict runs is still absent (verification VER-006). |
| EVAL-F-005 | info | Resolved and reconfirmed. Onboarding prints `not configured (set OPENAI_API_KEY)` style lines for all three providers (EVAL-010); `runtime.yml` carries no key values; a second `onboard` run against the same plain `.soft-foundry/` directory behaves identically. |
| EVAL-F-006 | info | Carried. `README.md` and `docs/user/README.md` still contain no user documentation for `init`: no description of the manifest, the five statuses, the `conflicts:`/`next:` lines, exit codes 0/1/3/4, `.soft-foundry/init.lock`, or how to opt into a `repository.yml` path override. Verification VER-007 (major) already flags the missing documentation for review; this is the same gap observed from the user's side. |
| EVAL-F-007 | info | Carried. The `updated` upgrade path for an owned `.ai/` file has end-to-end evidence (EVAL-004); the automated-test half (verification VER-001) remains open. |
| EVAL-F-008 | info | Every behaviour in AC-001..AC-016 matched the specification from the user's side across five personas and nineteen journeys at `a7b9df1`, and the three new legitimate-use journeys (EVAL-017..019) found no case where the V1..V7 hardening interferes with ordinary use. No journey failed. |
| EVAL-F-009 | info | New this run. `root:` is never printed on the Soft Foundry-internal-failure path (a broken package) because the packaged-file check in `Installer::Source.packaged` runs, and can raise, before the CLI prints `root:`; this is consistent with the "nothing was changed" guarantee but is worth a documentation sentence so an agent parsing for `root:` does not misread its absence as target misidentification (EVAL-012). |
| EVAL-F-010 | info | New this run. The V4 remediation's protected-group and emptied-override hardening does not constrain legitimate, non-empty `repository.yml` overrides of `APP`/`TESTS`/`INFRA` for a non-conventional repository layout; `check` and `init` behave identically to the conventional-layout case (EVAL-018). This is a positive confirmation, not a gap. |

## Evidence
All under `changes/init-command/07-evaluation/evidence/` (hashed in `evidence/manifest.yml`; the three archived runs' evidence lives under `previous/6a41afd123ca/`, `previous/c29509c3cee8/`, and `previous/a733f84086d0/` and is not listed there):
- `EVAL-001-first-install-idempotent.log` .. `EVAL-016-dry-run-conflict-preview.log` (re-executed with the same scripts as the third run, copied from `previous/a733f84086d0/evidence/scripts/`)
- `EVAL-017-gitignored-build-artifact.log`, `EVAL-018-repository-yml-override.log`, `EVAL-019-fresh-clone-block-detection.log` (new this run)
- `scripts/eval-001.sh` .. `scripts/eval-019.sh`, `scripts/lib.sh`

Evidence generated for a different implementation commit is stale.
