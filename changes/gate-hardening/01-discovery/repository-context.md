# Repository Context

Read at `a0a8460` on `change/gate-hardening` (main at `3e5627d`). Line numbers are from that tree.

## Discovered

**Architecture.** A Ruby gem (`soft_foundry`, version 0.22.0 in `lib/soft_foundry/version.rb`) with one executable, `exe/soft-foundry`, dispatching through `CLI#run` (`lib/soft_foundry/cli.rb:63-104`, 1,893 lines). `lib/soft_foundry/` holds 9,913 lines across about forty files. The parts this change touches:

- `gate.rb` (522 lines). The check list is hard-coded: `Gate.checks_for` (66-79) names them, `Gate#evaluate` (91-133) runs them. A skill's `completion.yml` supplies only `required_files` and a display-only `blocking` list (`control_plane.rb:13-14`); its `requirements.yml` is prompt context; its `permissions.yml` is read by the guard and `check`, never by the gate. `Gate::CHECKS` (35-61) is the explanation table; `harness_eval.rb:158` refuses an eval case that names a check absent from it, so every new check needs an entry there first.
- Status handling in `evaluate`: no handoff → `FAIL handoff present`; status `pending` → one `skip`; `in_progress` → one `warn`; `blocked` → `warn` (or `fail` if `blocking` is empty); `complete` → the full list. The `gate` command exits 2 only when a check is `:fail` (`cli.rb:799-808`), so a pending, reopened, in-progress or blocked phase named explicitly exits 0.
- `commit_check` (346-351): the SHA matches `/\A[0-9a-f]{7,40}\z/` and `git cat-file -e` finds it. It is not compared with HEAD or with any other phase's SHA.
- `staleness_check` (376-407), commit-bound skills only: fails on an invalid SHA; measures `changed_since(sha)` or `changed_between(sha, branch tip)` plus dirty paths against `code_globs` (APP, TESTS, INFRA), or `Scope#measure` for a scoped record; fails if the specification lock commit is not an ancestor of the commit that recorded this phase's handoff.
- `specification_lock_check` (293-304): the lock is `recorded_commit(specify)`; it is a `warn` ("not yet locked") until that handoff is committed; the handoff file itself is outside the lock.
- `recorded_commit` (`change_record.rb:198-207`): the last commit touching `<phase>/handoff.yml` whose blob says `status: complete`. `Scope#change_base` (`scope.rb:99-102`) is `recorded_commit(plan)`: the diff base for sizing, protection and scope advisories. Nil until the plan handoff is committed, and `protection_check` fails outright in that case (`gate.rb:448`).
- `red_evidence_check` (255-281), `scoped_verification_checks` (494-520, size and full-suite record via `full_suite.rb`), `protection_check` (440-483), `instincts_check` (242-247 via `learning.rb`), `findings_explained_check` (204-212), `panel_check` (218-237), `content_check` (190-197 via `content_scan.rb`).
- No gate code reads a `result:` field in `tests.yml`, a journey's `result:`, a case outcome, or the judgment verdict. `ChangeRecord#judgment_outcome` (`change_record.rb:292-300`) parses the `## Outcome` section of `final.md` and returns the single judgment word or nil; its only caller is `release.rb:149`.
- `change close` (`cli.rb:489-553`) refuses when: the record is released with open items; the judge handoff is not `complete`; `finished_commit_sha` is nil; that SHA is not an ancestor of the default branch; an `undischarged` item is unconfirmed. It does not read the verdict and does not run the gate.
- `ci` (`cli.rb:856-`): `check`, then the gate harness evals (live cases skipped), then `Gate#evaluate_all` on every record whose status is not `closed` or `released`; closed prints `(closed, skipped)`, released prints `(released, not re-gated)`. Skipped results are hidden (`results.reject(&:skipped?)`). The pre-commit hook `exec`s `soft-foundry ci`; a commit on this branch at `a0a8460` ran it in about two minutes.
- `change status` (`cli.rb:617-624`) runs `evaluate_all` on the named record with no closed-record branch visible at the call site.

**Who writes `current_phase`.** `phase_runner.rb:183-184` (`begin!`, before a fresh session), `cli.rb:1346-1348` (the same path), `phase_reopen.rb:55`, `change_record.rb:328/343/368` (`close!`, vet, reopen), `cli.rb:1293` (vet). No skill's `permissions.yml` names `metadata.yml`; the guard refused an `Edit` of it from the intake session on this change, and `Bash` is checked against deny sets only (`.ai/policies/enforcement.yml`), so an in-session agent advances the phase from the shell or not at all.

**What the runner does at the end of a session.** `PhaseRunner#finish!` stamps `executed_by` (exit status, finished_at, session id); `mark_blocked!` converts a complete-with-blocking handoff to `blocked`; the caller gates with `Gate#evaluate` directly (`cli.rb:1143`, `1282` for parallel, `1380`), never through the `gate` command's exit code. Nothing commits. The fresh-session prompt (`phase_runner.rb:150-166`) ends with "Stop when the handoff is written"; the parallel variant adds "do not commit anything". `ParallelRun` (`parallel_run.rb`) only spawns and waits.

**Git helpers available** (`git.rb`): `head_sha`, `commit?`, `ancestor?(sha, ref)`, `file_at?`, `changed_since`, `changed_between`, `diff_paths`, `tree_of`, `blob`, `blob!`, `last_commit_for`, `branch_tip`, `dirty_paths`, `status_entries`, `ref?`, `run(*args)`. Lineage and ancestry checks need nothing new; a sealing commit needs `run("add", …)` and `run("commit", …)`.

**Harness evals** (`harness_eval.rb`, 446 lines): a case is `{id, kind: gate|live, description, phase, record{risk, status, scope, skipped, complete, handoff, files, siblings}, application{files}, profile, expect{phase, outcome, check | finding}}`. `plant` (314-) copies `.ai/` into a scratch git repository, creates the record with `ChangeRecord.create`, completes the named phases at a bound commit with `complete_phase!`, merges handoff overrides, writes files with token substitution, and `run_gate` (255-275) compares the named check's outcome. `lint` refuses `expect.check` not in `Gate::CHECKS`. The cases directory is denied to this skill and to implementation; the maintainer's warn-mode override is the recorded route for adding cases, as on the last three changes.

**Tests.** Minitest under `test/` (about seventy files); `bundle exec rake test`. Helpers: `with_fixture_repo`, `with_target_repo`, `cli(dir, *args)` (does not clear the environment), `complete_phase!(record, id, sha:)`; `test/lifecycle_fixture.rb` gives `with_lifecycle_record` (a gated change with chosen phases complete at HEAD), `run_cli` (clears provider keys, `SOFT_FOUNDRY_PHASE`, `SOFT_FOUNDRY_PARALLEL`), and `FinishedFixture.with_finished_record(outcome:, undischarged:, merge:)`, which already rewrites `## Outcome` in `final.md`. Relevant existing files: `gate_test.rb`, `red_green_test.rb`, `protection_stated_test.rb`, `cli_change_close_test.rb`, `cli_change_new_options_test.rb`, `cli_change_summary_test.rb`, `phase_run_parallel_test.rb`, `phase_runner_test.rb`, `harness_eval_test.rb`, `learning_instincts_test.rb`.

**Baseline.** The full suite on `main` at `3e5627d`, run with `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `XAI_API_KEY` and `SOFT_FOUNDRY_PHASE` unset: 822 runs, 6,228 assertions, 0 failures, 0 errors, 769 s. The same suite fails 12 and errors 1 when it inherits `SOFT_FOUNDRY_PHASE` (`small-process-fixes` REV-009), because tests that use `test_helper`'s `cli` rather than `LifecycleFixture#run_cli` do not clear it.

**Templates the new checks will parse.** `tests.yml`: `commit_sha`, optional `size`, optional `full_suite{tree, command, outcome | cite}`, `checks[]{id, kind, command, result (pass|fail|error|skipped), evidence, criteria[], red_commit?, test_path?, protection?, protection_note?}`. `journeys.yml`: `commit_sha`, `journeys[]{id, criteria[], persona, starting_state, steps[], assertions[], evidence[], result (pass|fail|blocked)}`. `evidence/manifest.yml`: `commit_sha`, `artifacts[]{path, produced_by, sha256}`. `acceptance-criteria.yml`: `criteria[]{id, requirements[], given, when, then, verified_by[]}`. `final.md`: `## Outcome` followed by one judgment word (the unfilled template lists all four after the placeholder, which is why `judgment_outcome` returns nil when it finds more than one). `08-attack/cases.yml`: `cases[]{id, threat, …, result (denied|violated|blocked_by_provider|blocked_by_scope)}`; cases name threats, not acceptance criteria.

**Records that do not parse today.** `changes/scoped-verification/02-specification/requirements.yml` (line 81, an unquoted `fail closed:`), `07-evaluation/journeys.yml`, `06-verification/evidence/manifest.yml`; `changes/phase-lifecycle-controls/03-threat-model/threats.yml`; `changes/init-command/06-verification/previous/6df4d15e73d8/tests.yml` (an archived earlier run). All five records are `closed`.

**Residuals this change inherits**, from the three judgments' `residual-risk.md`:
- `scoped-verification`: REV-001 (record at the evidence commit whether `git.branch` resolved; measure HEAD if the ref appears later; three earlier attempts moved the hole), REV-003 (a `**`-scoped active record claims every path), REV-004 (`git:` as a string raises instead of a gate line), REV-006 (branch tip equal to the evidence commit), the unparseable `requirements.yml`.
- `phase-lifecycle-controls`: REV-008 (kill mid-rename leaves a partial reset), REV-009 (U+00A0 `discharged_at`), REV-004/REQ-027 (no `docs/user/` page for `phase reopen`, `--parallel`, `release`, `discharge`; no harness cases for a malformed release block, a non-isolated parallel request, a stale auto-reopen), REV-006 (reopen keeps `started_at`), REV-007 (`ps` shows one phase of a parallel run), EVAL-F4 (parallel session leaving `in_progress` prints pass), ATK-006/ATTACK-011 (held lock, symlinked lock, kill mid-write of release, discharge and parallel runs never executed), AC-014/D3 (gate on a pending phase exits 0; REQ-023 of that change forbade changing the meaning of a pending gate).
- `small-process-fixes`: REV-002 (`--type=`/`--risk=` equals form and a repeated flag ignored), REV-003 (`change summary` prints `none` for a string or mapping), REV-004 (format character in an `access_control` glob), REV-005 (summary follows a symlinked handoff), REV-006 (`check_vocabulary` ignores `tracks.forced_by_risk`), REV-008 (`warn:` after a failed blocked-mark omits the next step), REV-009 (suite inherits `SOFT_FOUNDRY_PHASE`), REV-010 (session-authored `blocked` exits 0 in parallel), REV-011 (red commit cites a different test file than the regression test).

**Unpromoted instincts.** `learn promote --dry-run` would promote about twenty entries at or above 0.80 (three at 0.90 from `factory-readiness`, three from `ui-*`, the rest at 0.85); seven are already in `.ai/rules/learned.md`. One of them, `verify-specification-yaml-parses-before-lock` (0.85, `scoped-verification`), is item 3 of this intake.

## Inferred
- The sealing command belongs in `CLI#phase` beside `run` and `reopen`: gate the phase with `Gate#evaluate`; on pass, `git add changes/<slug>/<phase>/ changes/<slug>/metadata.yml` and commit; advance `current_phase` and `status` in the same write so the guard's active skill moves with it. `phase run` calls it after `finish!` and `mark_blocked!` for a single phase, and after all outcomes, in lifecycle order, for `--parallel`. Confidence: inferred from the code paths above; the specification decides the name and the exact metadata transitions.
- "Predecessor recorded" is `recorded_commit(prev)` non-nil, a helper that exists; the message can name the sealing command.
- Lineage is two `ancestor?` calls: predecessor SHA to this SHA, and this SHA to HEAD (or the record branch tip, matching `Scope.tip_for`).
- The verdict check can reuse `judgment_outcome`; `FinishedFixture` already parametrizes the Outcome section for tests.
- AC coverage can be computed from `acceptance-criteria.yml` `criteria[].id` against `tests.yml` `checks[].criteria` and `journeys.yml` `journeys[].criteria`.
- Manifest recompute is `Digest::SHA256.file` against `artifacts[].sha256`, relative to the phase directory.
- A distinct `gate` exit code for an explicitly named non-complete phase cannot disturb `ci` (which uses `evaluate_all` and hides skips) or `phase run` (which calls `Gate#evaluate` directly).
- The equals-form option defect is in the `option("--name")` helper's contract (next argument only); `cli.rb:1074` already refuses `--env=` with a message, which is the precedent for either accepting or naming the form.

## Defined by repository policy
- `.ai/policies/enforcement.yml`: guard mode `block`; Edit/Write checked against write sets, Bash against deny sets only; the guard refuses writes to its own configuration from every skill.
- `.ai/policies/human-boundaries.yml`: "changes that intentionally weaken required controls" need a person; this change strengthens them. "Fabricating evidence" and "modifying another skill's evidence to obtain a pass" are never autonomous, which is why the five unparseable closed files are left alone.
- `.ai/workflow.yml`: `waivable_by_risk.high: []`; `forced_by_risk.high: gated`; review and judgment never waived; `isolated_phases: [evaluate, attack]`; `panel_phases` include specify, threat_model, plan, remediate, review.
- `.ai/rules/git.md`: commits represent coherent changes and must not hide failed evidence; never commit `.soft-foundry/` state or credentials.
- `.ai/policies/learning.yml`: promotion threshold 0.80; `learn promote` writes `.ai/rules/learned.md` through the change record on the current branch.
- `AGENTS.md` step 11: evidence phases run through `phase run` in fresh sessions; a limitation the guard cannot enforce is recorded in the handoff notes.

## Published policies
`.ai/repository.yml` `policies:` records privacy `NOT_APPLICABLE` (library gem; the only outbound calls are provider model listings and the RubyGems version check; the optional session ledger stays on the user's machine) and security `NOT_APPLICABLE` (maintainer decision 2026-09-15, `changes/security-policy-not-applicable`; no `SECURITY.md`). Terms: none published; the gem ships under its repository licence and has no service terms. No change here; this change alters nothing the tool collects, shares or retains.

## Unknown
See `unknowns.md`. None blocks specification.

## Affected components
See `affected-components.md`.

## Dependencies
See `dependencies.md`.
