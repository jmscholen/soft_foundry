# Change Intake

## User intent
Make Soft Foundry's completion gate refuse a change record whose evidence is hollow, and make phase completion self-sealing so that no person has to commit a phase for the specification lock and the verification diff base to exist. Close the loose ends still owed from `scoped-verification`, `phase-lifecycle-controls`, and `small-process-fixes` in the same pass so the gate can be called reliable.

The request follows an analysis of `lib/soft_foundry/gate.rb` at `3e5627d`, traced against a worked example in an adopter repository. The analysis found that every content check in the gate is presence-only by design, which is the intended boundary, but also found several places where the gate accepts a record that states its own failure, and one place where a correct outcome depends on a commit nobody is required to make.

## Desired outcome
Each item is an outcome the maintainer must be able to rely on after this change. The specification phase turns them into requirements; this list is the intent.

1. **Self-sealing phase completion.** When a phase is done, the agent runs one command that gates the phase and, on pass, commits that phase's directory and the change's `metadata.yml` in a single commit. `soft-foundry phase run` does this at the end of a single-phase session; a `--parallel` run seals each phase after every session returns. From then on, "predecessor complete" means the predecessor is recorded in history, not merely marked complete on disk, so the specification lock and the plan commit (the diff base) always exist by the time a later gate needs them. The person's only remaining git action is the pull request.
2. **The verdict is gated.** `gate judge` fails unless `final.md` states exactly one of the four permitted judgments. `change close` refuses a BLOCKED or REJECTED judgment without `--force`.
3. **Structured evidence parses.** Every required `.yml` file of a complete phase loads as YAML, and the specification's structured files parse before the specification can lock. A file that does not parse fails the gate with the file and the parser's line.
4. **A recorded test failure is a gate failure.** A check in `tests.yml` whose `result` is not `pass` fails verification unless the handoff names it under `blocking` or in a finding.
5. **`commit_sha` has lineage.** A complete phase's `commit_sha` is a descendant of, or equal to, the predecessor phase's `commit_sha`, and an ancestor of, or equal to, HEAD. An old SHA can no longer move the staleness baseline back.
6. **Acceptance criteria are covered.** Verification warns, and judgment fails, when an acceptance criterion id appears in no verification check's `criteria` and no evaluation journey.
7. **`gate` on a phase that is not complete is distinguishable.** Naming a pending, reopened, in-progress or blocked phase explicitly returns a distinct exit code so a script cannot read "nothing to gate" as a pass.
8. **Evidence files match their manifest.** The sha256 recorded for each file in `evidence/manifest.yml` is recomputed at gate time; a mismatch fails.
9. **Fresh-session review and judgment are required when the guard is enforcing.** When `.ai/policies/enforcement.yml` is in block mode, a review or judgment handoff without `executed_by.fresh_context: true` fails rather than advising.
10. **Owed command fixes land.** `change new` honours `--type=value` and `--risk=value` spellings; `change summary` names a malformed field instead of printing `none`; the test suite is isolated from an inherited `SOFT_FOUNDRY_PHASE`.
11. **History stays green.** Closed records are not re-gated by the new checks. `soft-foundry ci` on this branch and on `main` after merge passes with every existing record, including the five closed-record YAML files that already fail to parse.
12. **Every new check is explainable and tested.** Each new check has an entry in `Gate::CHECKS`, a harness-eval gate case that plants the defect it refuses, and a line in the user documentation. The phase-lifecycle commands from `phase-lifecycle-controls` (`phase reopen`, `phase run --parallel`, `change release`, `change discharge`) that still have no `docs/user/` page get one.
13. **Residuals from earlier changes are closed or explicitly carried.** REV-001 of `scoped-verification` (record whether `git.branch` resolved at the evidence commit); the attack lock and symlink cases from `phase-lifecycle-controls` that were never run under the guard; instincts at or above 0.80 that have not been promoted.

## Constraints
- No new check may run the application's test suite, re-run a test, or judge whether a claim is true. The boundary the code states today ("a record, not a test result"; "presence only; whether a claim is true is for review") stands. Each new check verifies a structural fact the record itself asserts.
- No person is required to commit a phase. Any step this change adds to a phase's completion is performed by the tool or by the agent in the phase session.
- The guard stays in block mode in this repository. Text this change owes under `.ai/**`, `README.md`, or harness evals is written under the maintainer's documented warn-mode override and recorded in the implementation handoff, as on previous changes.
- Existing records on `main` must pass `soft-foundry ci` unchanged. A closed record is never edited to satisfy a new check.
- The suite is run with provider keys and `SOFT_FOUNDRY_PHASE` unset before any evidence is recorded, because this machine exports keys that CI does not have.
- Review and judgment run in fresh sessions through `soft-foundry phase run`, on a provider other than the implementing one where one is installed.

## Non-goals
- Gating the evaluate and attack sizes that `change size` computes.
- Verifying the truth of a `protection: in_force` claim.
- Any change to the adopter repository the analysis used as its example; its control-plane refresh is separate work.
- Changing which phases exist, their order, or the two lifecycle tracks.
- Interpreting the `transitions`, `rules`, or skill `completion.yml blocking` lists that are documented but not read by code, beyond what items 1 to 9 require. Making those inert declarations either live or removed is a follow-up.

## Task classification
`feature`. The change adds a command (phase sealing), seven gate checks, three command fixes, harness-eval cases, and documentation. It touches `lib/`, `exe/`, `test/`, `.ai/harness-evals/`, `.ai/skills/*/SKILL.md` text, `docs/user/`, and `README.md`.

## Initial risk
`high`. The gate is the control every other change depends on. A defect in this change either lets a hollow record pass, which defeats the process, or refuses every record, which stops the repository. High risk forces the gated track and allows no phase to be waived; that is the correct posture for a change to the gate itself.
