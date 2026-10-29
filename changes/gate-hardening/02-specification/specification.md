# Specification

## Intent
Soft Foundry's completion gate refuses records whose evidence is hollow, and a phase is sealed into history by the tool rather than by a person remembering to commit. The gate keeps its boundary: it verifies structural facts a record asserts about itself and never runs the suite or judges whether a claim is true. After this change, a maintainer who sees a passing gate knows, in addition to what the gate establishes today, that every structured evidence file parses, that no test the record lists is recorded as failing without being named, that every phase's commit descends from its predecessor's, that every acceptance criterion was either checked or explicitly set aside, that evidence files match their manifest, that a judgment says one of the four permitted words, that review and judgment ran in fresh sessions where the repository demands it, and that every one of those phases is in git because the tool put it there.

The loose ends from `scoped-verification`, `phase-lifecycle-controls` and `small-process-fixes` that are small enough to close in the same pass are closed here; the ones that are not are carried with the reason written down (REQ-027).

## Personas and authorization boundaries
- **The phase session** (a coding shell running one skill, under the guard). May write its own phase directory. May run `soft-foundry phase seal <phase>` for the phase it is on. May not write `metadata.yml` with a file tool; the sealing command does that for it.
- **`soft-foundry phase run`** (the runner, a parent process outside the guard). Starts a fresh session, stamps `executed_by`, and seals the phase when the session returns and the gate passes.
- **The maintainer.** Opens pull requests, merges, closes, releases, discharges, and may pass `--force` where a command offers it. Owns the warn-mode override for text the implementation skill may not write.
- **`soft-foundry ci`** (the pre-commit hook and GitHub Actions). Reads records; writes nothing.
The authorization boundary is unchanged: a committer can still edit any file. The gate's job is to make an edit that fakes a pass detectable, not impossible.

## Functional behavior

### A. Sealing a phase (REQ-001 to REQ-006)
`soft-foundry phase seal <phase> [--change SLUG]` is the one command a session runs when its phase is done. It:
1. Requires the phase's handoff to say `status: complete`; otherwise it refuses, naming the status it found and that the handoff must be completed first (exit 1).
2. Refuses when any path matching the repository's APP, TESTS or INFRA globs is dirty, untracked or ignored-but-present in the worktree, naming up to five of them: the handoff's `commit_sha` describes committed code, so uncommitted code may not be sealed over (exit 1). Other dirty paths (another phase's directory, a scratch file) are left alone and named in a `note:` line.
3. Runs the phase's completion gate. On any failing check it prints the gate result and exits 2 with nothing written and nothing committed.
4. On pass, in one write under the record lock: sets `metadata.yml` `current_phase` to the first phase after this one that is pending and not skipped-with-rationale (unchanged if none), sets `status` to `in_progress` if it was `intake` and to `judged` when the sealed phase is `judge`; then stages exactly `changes/<slug>/<phase output>/` and `changes/<slug>/metadata.yml` (and `changes/<slug>/budget.yml` when it changed) and commits with the message `Record <slug> <phase id>`. The pre-commit hook runs as for any commit; `--no-verify` is never passed.
5. Prints `sealed <phase output> at <sha>`, exit 0. Run again on a phase whose directory and metadata are already committed and unchanged, it prints `already sealed at <sha>` and exits 0.
6. If the commit itself fails (the hook refused, or git failed), it prints the failure, leaves the metadata change in the worktree, and exits 2; running it again after the cause is fixed completes the seal.

`soft-foundry phase run <phase>` seals the phase after `finish!` and `mark_blocked!`, when the handoff is `complete` and the gate passes. A handoff left `in_progress`, `blocked`, or failing its gate is not sealed and the runner's exit code says so (2). `phase run A B --parallel` seals each phase that passed, in lifecycle order, after every session has returned; a phase that failed is left unsealed and named. The fresh-session prompt's last step says the runner seals the phase and that the session must not commit.

The gate's `predecessor complete` check now requires the predecessor to be **recorded**: its handoff committed with `status: complete` (`recorded_commit` non-nil). A predecessor that is complete on disk but not in history fails with a message naming `soft-foundry phase seal <predecessor>`. The parallel ordering above satisfies this for evaluate and attack.

Sealing a commit-bound phase also records whether `metadata.git.branch` resolved at that moment (REQ-020), closing the measure gap `scoped-verification` REV-001 left open.

### B. Checks the gate adds (REQ-007 to REQ-015)
Each check has a `Gate::CHECKS` entry, runs only on a `complete` handoff, and reports `skip` with the reason on a record whose `status` is `closed` or `released`, so a historical record is read by the gate that closed it. In the order `checks_for` lists them:

| Check | Phases | Verifies | Does not verify |
| --- | --- | --- | --- |
| `structured files parse` | every phase | each required `.yml` file, plus `evidence/manifest.yml` when present, loads with `YAML.safe_load` (Time, Date, aliases) as a mapping; detail names the file and the parser's line and column | any field |
| `commit lineage` | every phase with a predecessor | the predecessor's `commit_sha` is an ancestor of or equal to this one; this one is an ancestor of or equal to the measuring tip (the recorded branch tip `Scope.tip_for` uses, else HEAD) | that the SHA is the one the outputs describe |
| `test results recorded` | verify | `tests.yml` `checks` is a non-empty list; each has `id`, `kind`, `command`, `result` in `pass fail error skipped`; a check whose `result` is `fail` or `error`, or `skipped` with non-empty `criteria`, is named by id in the handoff's `blocking` or `findings` | that the command ran or produced the result |
| `criteria covered` | verify (warn), judge (fail) | at verify: every `criteria[].id` in `02-specification/acceptance-criteria.yml` appears in some `tests.yml` check's `criteria`; missing ids are a `warn`. At judge: every id appears in a verify check's `criteria` or an evaluation journey's `criteria`, or in `14-judgment/evidence.yml` `criteria_not_covered` with a non-empty `reason`; otherwise `fail` naming the ids | that the test or journey actually exercises the criterion |
| `evidence manifest verified` | verify, evaluate, attack | every `artifacts[].path` exists under the phase directory and its SHA-256 equals `sha256` (hex, case-insensitive); a file under `evidence/` other than `manifest.yml` that no artifact names is a `warn` | what the file contains |
| `verdict recorded` | judge | `ChangeRecord#judgment_outcome` returns one of the configured judgments; detail is the word | that the word is justified |
| `fresh session recorded` | review, judge | when `.ai/policies/enforcement.yml` `guard.mode` is `block`: the handoff's `executed_by` is a mapping with `runner: soft-foundry phase run` and `fresh_context: true`; otherwise `skip` (the advisory stands) | that the session was in fact fresh |

The machine-local enforcement override and `SOFT_FOUNDRY_GUARD` are not consulted by the gate: the repository's policy decides what its records must show.

### C. Commands (REQ-016 to REQ-019)
- `gate <phase>` naming one phase whose handoff is not `complete` exits **3**; the printed line is unchanged (`SKIP` for pending, the warn line for in_progress and blocked). `gate all`, `ci`, `phase run` and `change status` are unaffected; `gate --help`-style usage text lists the codes 0, 2, 3.
- `change close` refuses, without `--force`, when `judgment_outcome` is `BLOCKED` (message names `remediate`) or `REJECTED` (names `intake`), after the existing judge-complete check and before the merged check.
- `change new` accepts `--type=VALUE`, `--risk=VALUE`, `--track=VALUE`, `--title=VALUE`, `--branch=VALUE`, `--scope=VALUE` as the spaced forms, through the shared option helper, and refuses a flag given twice (`--type given twice`). `--env=` keeps its own refusal.
- `change summary` prints `blocking: malformed (<field> is a <Class>, expected a list)` and the same for `findings`, for each phase whose field is not a list; exit stays 0.

### D. Residuals closed here (REQ-020 to REQ-026) and carried (REQ-027)
Closed: REV-001 measure recording (`scoped-verification`); `git:` as a non-mapping in `metadata.yml` becomes a gate line (REV-004); `phase reopen` clears `started_at` (REV-006, `phase-lifecycle-controls`); `ps` names every phase of a parallel run (REV-007); a `discharged_at` that is only Unicode blanks is open (REV-009); `check_vocabulary` compares `tracks.forced_by_risk` keys (REV-006, `small-process-fixes`); the `warn:` after a failed blocked-mark says what to do next (REV-008); a session-authored `blocked` handoff makes a parallel run exit 2 (REV-010); `change summary` and `phase seal` refuse a symlinked `handoff.yml` or `metadata.yml` (REV-005); the suite passes when it inherits `SOFT_FOUNDRY_PHASE` (REV-009); the held-lock, symlinked-lock and kill-mid-write cases are run by this change's attack phase against `phase seal` (ATTACK-011); `learn promote` runs on this branch (DISC-008).
Carried, with the reason in `readiness.md` and the final judgment: REV-003 (`**` scope), REV-008 (kill mid-rename journal), REV-011 (red commit cites a different file), REV-004 (format character in a glob), the interpretation of the inert `transitions`/`rules`/`completion.yml blocking` declarations beyond what this change needs.

### E. Documentation, evals, rules (REQ-028 to REQ-031)
Every new check and command is in `README.md` and in `docs/user/`; the four phase-lifecycle commands that never got a page get one; every new check has a harness-eval gate case; the three cases `phase-lifecycle-controls` owed are added; promoted instincts land in `.ai/rules/learned.md`.

## Accessibility
`surfaces.accessibility: true`: every output of this change is text a person reads in a terminal or a CI log. Requirements REQ-032: every new refusal or gate line is plain text on one line (continuation facts on following lines), names the file or check, the value found, and the next action; meaning is never carried by colour alone (the existing ✓/✗/-/! marks remain alongside the words); file paths are repository-relative; SHAs are shown as 12 characters with the full value available in `--json`. Per `.ai/rules/accessibility.md`.

## Data and consistency
- `metadata.yml` gains no required key. `14-judgment/evidence.yml` gains an optional `criteria_not_covered: [{id, reason}]`. A commit-bound phase's `handoff.yml` gains `branch_resolved: true|false`, written by `phase seal` (REQ-020).
- Sealing writes metadata and handoff under the existing record lock (`ChangeRecord#update_metadata`, `update_handoff`); the git commit follows the write. A crash between the write and the commit leaves the worktree in the exact state a rerun of `phase seal` completes from.
- Old records: a handoff without `branch_resolved` is measured as today. A judgment `evidence.yml` without `criteria_not_covered` means none were set aside.
- Closed and released records are never re-gated by the new checks (every one reports `skip` there), and no closed record is edited.

## Failure behavior
- Every new check fails closed: a file that cannot be read, a SHA git cannot resolve, a manifest path outside the phase directory, a `git:` that is not a mapping, each produce a `fail` line with the cause and the next step, never a Ruby exception (REQ-021).
- `phase seal` with a failing gate, dirty code, a non-complete handoff, or a refused commit writes nothing to git and exits 1 or 2 as above.
- `phase run --parallel`: when one session fails, the others' phases are still sealed in order; the exit is 2; the output names which phase was sealed and which was not.
- A missing git repository turns `commit lineage`, `evidence manifest verified` (unchanged: it needs only the filesystem, so it still runs), and the sealing command into `skip`/refusal with "no git repository", as the existing commit-bound checks do.

## Security requirements
- REQ-033: `phase seal` stages only the paths named in A.4, by explicit path, never `-A`, so a planted file elsewhere in the worktree is not committed by the tool.
- REQ-034: `phase seal`, `change summary` and the gate refuse to follow a symlink at `handoff.yml`, `metadata.yml`, `tests.yml`, `journeys.yml`, `acceptance-criteria.yml`, `evidence.yml` or `evidence/manifest.yml`, and `evidence manifest verified` refuses an artifact path that resolves outside the phase directory.
- REQ-035: no new check or command reads the network, a credential, or the machine-local enforcement override; values from `--env` are never printed by the parallel sealing path.
- The threat model covers: a committer forging `executed_by`, `branch_resolved`, or `criteria_not_covered`; a session running `phase seal` on another phase; the hook being bypassed with `--no-verify` by a person.

## Privacy and security policy conformance
`surfaces.policy: false`. The repository profile records privacy and security policies as NOT_APPLICABLE (library gem; nothing about a person is collected, shared or retained). This change adds no outbound call, stores nothing new about a person (`executed_by` already records a session id and cwd; `branch_resolved` is a boolean), and changes no promise. No policy text is owed.

## Performance and resource limits
- REQ-036: the new checks add no git subprocess beyond `ancestor?` (two calls per phase) and `rev-parse` for the tip; SHA-256 is computed once per listed artifact; `gate all` on this repository's largest open record stays under twice its current wall time, measured at evaluation.
- `phase seal` runs the pre-commit hook; that cost is the hook's, recorded in evaluation, and is the price of the hook meaning something.

## Infrastructure implications
None. No new gem, no CI change. GitHub Actions already runs the suite without provider keys.

## Observability expectations
- Each sealing commit is observable in `git log` as `Record <slug> <phase>`; `soft-foundry ui` and `change status` show the recorded commit as today via `recorded_commit`.
- `gate --json` (existing) carries every new check with name, outcome and detail, and the `verdict recorded` detail carries the word, so a dashboard can read the verdict without parsing markdown.
- No metrics or alarms: a CLI, not a service.

## Acceptance criteria
In `acceptance-criteria.yml`: AC-001 to AC-055, each naming its requirements; every requirement REQ-001 to REQ-036 is named by at least one. Every criterion is a command or a gate run against a fixture record and an observable exit code, line, file, or commit, so each can be a minitest and a harness-eval case.
