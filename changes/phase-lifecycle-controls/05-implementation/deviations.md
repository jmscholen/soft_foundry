# Deviations From Plan

Each deviation records: what changed, why the plan could not be followed, which requirements are affected, and who must approve it.

## D1. Control plane, documentation, README and harness-eval cases not written (plan step 8, and the `isolated_phases` line of step 4)
- **What:** `.ai/workflow.yml` (`isolated_phases`), `.ai/templates/change/metadata.yml`, `.ai/schemas.md`, `.ai/README.md`, `.ai/harness-evals/cases/*` (two gate cases and one live case), the repository `README.md`, and `docs/user/` are untouched. The code that reads them is done and tested against fixture control planes.
- **Why:** the implementation skill's `permissions.yml` denies writes to `${CONTROL_PLANE}` (`.ai/**`) and `${DOCS}` (`docs/**`), the harness evals are denied for read and write, and the root `README.md` is in no write set. The plan assigned these files to implementation; a skill must not do work its permissions forbid to manufacture a pass. The exact text owed is in `owed-control-plane-and-docs.md`.
- **Requirements affected:** REQ-009 and REQ-010 (until `isolated_phases: [evaluate, attack]` is added to `.ai/workflow.yml`, `--parallel` refuses with "no isolated_phases declared"), REQ-027, AC-045 (the harness-eval part), AC-050, and the shipped-list half of AC-018. `phase_lifecycle_docs_test.rb` and the two gate cases were not written because they could not pass.
- **Approval:** a person with write access to `.ai/` and `docs/` (a maintainer) applies `owed-control-plane-and-docs.md`; the documentation could alternatively come from the optional `document` phase for `docs/user/`. The change should not close before this is done.

## D2. `downstream` follows only `next` transitions, and not from phases reached by lifecycle order
- **What:** the plan says transitions are followed "to a fixed point". Implemented: lifecycle successors, plus the `next` edge of the reopened phase and of phases reached by such an edge. `downstream(judge)` is `[learn]`, not empty as `testing.md` wrote.
- **Why:** AC-001 (reopen evaluate leaves verify complete) and AC-002 (reopen remediate resets verify) cannot both hold if every edge of every reached phase is followed, because remediate sits after evaluate in lifecycle order and `next`s to verify; judge's `on_rejected` would reach intake.
- **Requirements affected:** REQ-002 (read as the acceptance criteria require). **Approval:** reviewer.

## D3. The gate does not fail a reopened (pending) phase (AC-014)
- **What:** after a reopen, `soft-foundry gate <phase>` reports the phase as pending with a skip and exits 0; the test asserts that, and that `change close` is refused.
- **Why:** the existing gate treats a pending phase as not yet started (REQ-023 forbids changing its meaning). The effect AC-014 wants (a reopened phase cannot read as done) holds: `current_phase` points at it, its handoff is pending, no command marks anything complete, and close is refused. **Requirements affected:** REQ-007. **Approval:** reviewer.

## D4. `PhaseRunner#refusal` keeps accepting a stale complete phase (plan step 3)
- **What:** no `allow_stale:` keyword was added. `refusal` already returned nil for a complete phase whose evidence is stale (an existing test, `test_a_stale_complete_phase_may_be_rerun_by_phase_run`, pins that), so the auto-reopen happens in `Cli#phase` after every refusal has been evaluated, and `stale_complete?` / `stale_reason` were added to the runner.
- **Why:** the plan's premise (a refusal being replaced) did not match the code. AC-008/AC-009 hold (a current phase is refused; a stale phase with an incomplete predecessor is refused with nothing reset). **Approval:** reviewer.

## D5. Extra and reworded behaviour in the parallel run
- `refusal(phase, named:)` was added so a named predecessor counts as satisfied when its own predecessor is complete. A parallel run also refuses if `--parallel` is combined with `--panel`, `--max-rounds` or `--shell-arg`, and when `isolated_phases` is absent.
- `current_phase` after the run steps over skippable pending phases (decisions.md). Per-session failure to start (missing shell) is reported as `phase <id>: could not run: ...` followed by `phase <id>: fail`.
- The runner records the session's `commit_sha` only through the instruction it gives the session (the prompt names the start HEAD and says not to commit); it does not rewrite a handoff's `commit_sha`. A differing HEAD at the end gives the `warn:` line and a non-zero exit.

## D6. `--env` values on the soft-foundry command line (REQ-012)
- **What:** `ps` shows the soft-foundry process's own arguments, so `--env NAME=VALUE` would appear in it. The process title is rewritten with the values masked as soon as arguments are parsed. A window of microseconds before the rewrite, and the person's shell history, remain.
- **Why:** REQ-012 says `ps` output never holds a value; the only alternative (reading values from a file or the environment) is a different interface. **Approval:** reviewer decides whether a `--env-file` style input is wanted later.

## D7. Release preconditions beyond the specification
- `change release` also refuses when any gate fails and when the judgment outcome cannot be read as one word (plan risk R-3 and the template listing all four words). Discharged items also record `discharge_commit`. Carried items carry `from: judgment`.

## D8. `ci` for a released record that is not merged and has no open items
- Prints a notice and passes (the specification only says a merged one fails). **Approval:** reviewer.

## D9. Test edits after their RED commit
- Within slices 2, 5, 6 and 7 a few assertions in the new test files were corrected after the first run showed the test, not the code, was wrong (a regex, a fixture that needed no commit, ASCII-only applied to the existing gate glyphs, a memoised `Scope`). No existing test file was edited, and no assertion about behaviour was weakened.

## D10. Test coverage not written
- `phase_lifecycle_docs_test.rb` (AC-050) and the shipped-list assertion in AC-018 (they need D1). The harness gate cases and the live stale-auto-reopen case (AC-045, REQ-027) need D1; a live case also needs a real coding shell.
- The `ps` command's own listing of a parallel run was not extended: `phase_of` reads the first phase only (`soft-foundry phase run evaluate attack --parallel` shows as evaluate).
