# Evaluation Results

Commit SHA: 6a41afd123ca1ea6f72b1ac6b686e2b2c419b10e (branch `change/init-command`)

Runtime: ruby 3.3.1 (`/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby`), Soft Foundry run from source at this commit (`ruby -I<repo>/lib <repo>/exe/soft-foundry`). Fifteen journeys, four personas, executed against fresh scratch repositories; every command, its combined output, its exit code, and the post-state are in the transcripts under `evidence/`. The scripts that produced the transcripts are in `evidence/scripts/`. No file outside `changes/init-command/07-evaluation/` was modified by this phase; the repository worktree carried only the pre-existing `metadata.yml` change (`current_phase: evaluate`) plus this phase's files.

## Journey outcomes
| Journey | Persona | Criteria | Result | Evidence |
| --- | --- | --- | --- | --- |
| EVAL-001 first install, commit, re-run | (a) | AC-001, AC-003, AC-010 | pass (17/17 assertions, including the stretch mtime check) | `evidence/EVAL-001-first-install-idempotent.log` |
| EVAL-002 existing AGENTS.md and CLAUDE.md preserved | (b) | AC-004, AC-005 | pass (11/11) | `evidence/EVAL-002-pointer-files-preserved.log` |
| EVAL-003 dry-run preview then real run | (c) | AC-012 | pass (7/7) | `evidence/EVAL-003-dry-run-then-real.log` |
| EVAL-004 committed edit: conflict, `updated` sibling, then `--force` | (a)/(b) | AC-006, AC-007, AC-003 | pass (11/11) | `evidence/EVAL-004-conflict-then-force.log` |
| EVAL-005 uncommitted edit stays conflict even with `--force` | (b) | AC-006 | pass (6/6) | `evidence/EVAL-005-uncommitted-edit.log` |
| EVAL-006 non-git refusal, `--allow-non-git`, `--force` refused with it | (c) | AC-002 | pass (5/5) | `evidence/EVAL-006-non-git.log` |
| EVAL-007 docs/ without docs/user/ | (a) | AC-011 | pass (4/4) | `evidence/EVAL-007-docs-without-user.log` |
| EVAL-008 .gitignore already effective; append case | (b) | AC-009 | pass (4/4) | `evidence/EVAL-008-gitignore.log` |
| EVAL-009 `--root` subdirectory refusal; root printed | (c) | AC-001, AC-002 | pass (6/6) | `evidence/EVAL-009-root-option.log` |
| EVAL-010 onboarding with no provider keys | (a) | AC-015 | pass (7/7) | `evidence/EVAL-010-no-provider-keys.log` |
| EVAL-011 status words survive non-ASCII stripping | (c) | AC-016 | pass (6/6) | `evidence/EVAL-011-ascii-status-words.log` |
| EVAL-012 broken package: exit 4 and upstream guidance | (a) | AC-013 | pass (10/10) | `evidence/EVAL-012-internal-failure.log` |
| EVAL-013 hand-copied .ai/ without manifest | (d) | AC-008, AC-010, AC-007 | pass (11/11) | `evidence/EVAL-013-hand-copied-ai.log` |
| EVAL-014 CLI scripting surface | (c) | specification "Exit codes" (no AC id) | **fail** (4/5) | `evidence/EVAL-014-cli-surface.log` |
| EVAL-015 .ai symlinked outside the repository | (b) | AC-014 | pass (4/4) | `evidence/EVAL-015-symlinked-ai.log` |

Acceptance criteria coverage: AC-001 through AC-016 each have at least one passing journey. AC-017 (gem contents, `required_ruby_version`) is a packaging property proven by verification check 9 and was not repeated as a journey.

Notable confirmations beyond the criteria:
- The `updated` status for an owned `.ai/` file whose canonical content changed (the upgrade path, VER-001 gap) is now exercised end to end: EVAL-004 step 4 shows `updated   .ai/rules/ruby.md  (owned by manifest)` with the file rewritten, the manifest hash refreshed, and only that file and the manifest modified.
- Idempotency holds at the modification-time level: EVAL-001 recorded `stat` mtimes of all 172 managed files before and after the second run and found them identical.
- The internal-failure diagnostic is clean: with canary values in all three provider variables, neither stdout nor stderr contained the canary, the absolute target path, the absolute source path, or the home directory (EVAL-012); the source path appeared only as `source: <soft-foundry>`.
- `--force` never touched `.ai/repository.yml` (EVAL-013, `assessed: true` preserved through a forced run) and is refused together with `--allow-non-git` (EVAL-006).

## Failures

### EVAL-014 step 5: `soft-foundry init --root` with no value is classified as a Soft Foundry defect
- Expected (specification, "Exit codes": `1` usage or environment error; "Failure behavior": target-side failures get a plain explanation): exit code 1 and a one-line `soft-foundry: --root requires a value` style message.
- Observed (`evidence/EVAL-014-cli-surface.log`, step 5): exit code 4 and
  ```
  soft-foundry: internal failure in installer: ArgumentError: --root requires a value
  This is a defect in Soft Foundry 0.2.0, not in your repository. Nothing further was changed.
  diagnostic:
    <soft-foundry>/lib/soft_foundry/cli.rb:142:in `option'
    <soft-foundry>/lib/soft_foundry/cli.rb:70:in `init'
    <soft-foundry>/lib/soft_foundry/cli.rb:33:in `run'
    <soft-foundry>/exe/soft-foundry:6:in `<main>'
  Help fix it upstream: fork https://github.com/jmscholen/soft_foundry, reproduce with the diagnostic above, and open a pull request or issue.
    gh repo fork jmscholen/soft_foundry --clone
  ```
- Impact: an agent branching on exit codes (persona c) treats its own malformed invocation as a Soft Foundry failure; a maintainer is told to fork the upstream repository and open an issue for a typo. Nothing is written to the target, so there is no data impact. The same message shape is correct for the genuinely broken package in EVAL-012, which is why the misclassification matters: it dilutes a signal the specification reserves for Soft Foundry-side faults.
- What the transcript shows about the cause (observation, not a fix): the option parser raises `ArgumentError`, and `init`'s catch-all wraps every non-`Error` exception as an internal failure. Compare `--dry_run` and `--help` in the same transcript, which the parser reports as `unknown option(s)` with exit 1.
- Result: the assertion `--root without value refused with exit 1` fails; the journey fails; the phase is `blocked` on it (handoff `blocking`).

No other assertion failed. Four transcripts (EVAL-010, EVAL-011, EVAL-013, EVAL-014) were regenerated once after fixing defects in the evaluation harness itself (an unexpanded `$LOG` inside a command substitution, a grep that matched the harness's own command line, and one post-condition checked after the `--force` step it was meant to precede). The expected outcomes were not changed; the regenerated transcripts replaced the earlier ones and the scripts in `evidence/scripts/` are the fixed versions.

## Report usability
The terminal report is the product's whole UI, so it was assessed on its own terms. These are findings, not failures; none violates a criterion except where noted in the failure above.

- **Status words.** `created`, `skipped`, `conflict`, `forced` are self-explanatory. `updated` is used for three different things: a pointer file that had a block appended, `.gitignore` that had a line appended, and an owned `.ai/` file rewritten to new canonical content; the reason in parentheses disambiguates (`block appended`, `appended .soft-foundry/`, `owned by manifest`), which is adequate but requires reading the reason.
- **Reasons.** `skipped` reasons are good: `identical`, `block present`, `user-owned scaffold`, `docs/ exists without docs/user/`, `.soft-foundry/ is ignored`, `repository state is owned by this repository`. `conflict` reasons (`differs from manifest hash`, `not in manifest`, `uncommitted modifications`) are precise but written from the installer's point of view; a first-time maintainer has to know what the manifest is to understand the first two. None of them says what to do next.
- **Resolving action for conflicts.** The specification's failure behaviour says target-side failures, including conflicts, print "the flag or action that resolves it". On a conflict run (EVAL-004 step 4, EVAL-005, EVAL-013 step 1) the output is the `conflict` line(s), `check: ok`, the `summary:` line, and exit 3; `--force`, `git commit`, and `git checkout` are never mentioned. The only guidance text (`check: failed, resolve the conflicts above and rerun`) appears only when the control-plane check itself fails, which it did not in any journey. `check: ok` printed immediately before an exit-3 summary also reads as success to a skimming reader.
- **Summary line.** `summary: created N, updated N, skipped N, conflict N, forced N` gives the counts a maintainer needs to decide whether to commit (all `created`/`skipped`), review a diff (`updated`/`forced` > 0), or intervene (`conflict` > 0). It does not repeat the conflicted paths, so on a 171-line report the maintainer must scroll or grep for `^conflict`. The MIT-004(b) `git diff` hint for `updated`/`forced` (already VER-006) and the MIT-004(c) ordering of `updated`/`forced` first under `--dry-run` are not present; lines are emitted in fixed path order (`.gitignore`, `AGENTS.md`, `CLAUDE.md`, then `.ai/` alphabetically, then scaffolds).
- **Resolved root.** `root: <absolute path>` is the first line of every report including `--dry-run` (EVAL-001, EVAL-003, EVAL-009), so the user sees where writes go before they happen. Refusals name the offending path and the flag that resolves them in one sentence (EVAL-006, EVAL-009, EVAL-015).
- **Onboarding section.** `openai     not configured` tells the maintainer the state but not the variable to set (`OPENAI_API_KEY` and so on), and `init` itself has no way to show it without running bare `soft-foundry`.
- **Help.** `soft-foundry init --help` is rejected as `unknown option(s): --help` with exit 1. The option list exists only in the top-level help printed by bare `soft-foundry`.
- **Length.** A first install prints 171 file lines before `check:` and `summary:`. This is honest and greppable, but the decision-bearing lines are at the bottom.

## Accessibility observations
- Keyboard-only interaction: not applicable. The command is non-interactive; every journey, including refusals, conflicts, and the internal failure, returned without reading input. There is no prompt, focus, or navigation to test.
- Screen-reader readability: every outcome is a word. EVAL-011 captured raw bytes of three runs covering all five statuses (8439, 10740, and 10740 bytes) and found zero non-ASCII bytes and no escape sequences; after stripping to printable ASCII, every status was still identifiable by its first word and per-status counts matched the `summary:` line exactly. Output is line-oriented with fixed prefixes (`root:`, `mode:`, `check:`, `summary:`, `warning:`, `soft-foundry:` for errors) that can be jumped to.
- Colour: none emitted, so `NO_COLOR` is honoured and monochrome or high-contrast terminals see the same text.
- Limitation: a single `conflict` among 170 `skipped` lines is found only by searching for the word or by counting from the summary; grouping conflicts or listing them after the summary would help screen-reader users and sighted users equally (see findings EVAL-F-003 and EVAL-F-004).

## Findings
| ID | Severity | Summary |
| --- | --- | --- |
| EVAL-F-001 | major | `init --root` with no value exits 4 with "This is a defect in Soft Foundry" and fork/pull-request guidance instead of a usage error with exit 1 (specification "Exit codes"); the option parser's `ArgumentError` is wrapped as an internal failure. EVAL-014 fails on this. |
| EVAL-F-002 | minor | `init --help` is refused as `unknown option(s): --help` with exit 1; there is no per-command help, only the top-level listing from bare `soft-foundry`. |
| EVAL-F-003 | minor | Conflict runs print no resolving action: no mention of `--force`, `git commit`, or `git checkout`, contrary to the specification's failure-behaviour text; `check: ok` directly precedes an exit-3 summary and reads as success. |
| EVAL-F-004 | minor | The summary line does not name conflicted paths and conflicts are interleaved in path order among up to 170 `skipped` lines; the MIT-004 `git diff` hint (VER-006) and the dry-run ordering of `updated`/`forced` first are absent. |
| EVAL-F-005 | minor | Onboarding reports `not configured` per provider without naming the environment variable (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `XAI_API_KEY`) a maintainer must set. |
| EVAL-F-006 | info | Conflict reasons (`differs from manifest hash`, `not in manifest`, `owned by manifest`) presume the reader knows what `.ai/manifest.yml` is; user documentation (10-user-documentation) should define it and the five statuses. |
| EVAL-F-007 | info | The `updated` upgrade path for an owned `.ai/` file now has end-to-end evidence (EVAL-004: `updated .ai/rules/ruby.md (owned by manifest)`), closing the evidence half of VER-001; the automated test half remains open. |
| EVAL-F-008 | info | Every other behaviour in AC-001 through AC-016 matched the specification from the user's side: idempotent to the mtime, pointer prose preserved byte for byte, uncommitted edits never overwritten even with `--force`, no secrets or absolute paths in the internal-failure diagnostic, nothing written on any refusal. |
