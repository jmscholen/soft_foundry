# Residual Risk

Judged commit: `72cc1e95d224fdcf2421e275dd68912f9df6f850`. Outcome: APPROVED_WITH_RESIDUAL_RISK.

| Risk | Source | Likelihood | Impact | Accepted by | Mitigation owed |
| --- | --- | --- | --- | --- | --- |
| The branch is not merged. A clean checkout of `72cc1e9` fails `ci` until this phase directory is in the commit. GitHub Actions has not run on the branch. | REV-001 after `72cc1e9`; REQ-REL-002; REL-002 | Certain until the seal is pushed and the pull request merges. The missing-handoff failure on a checkout of `72cc1e9` is one phase, `14-judgment`. | The pull request is red, or it is never opened, and 0.23.0 stays off `main`. | This judgment, as an open release condition | Push the seal of this phase. Open the pull request. Merge to `main`. Confirm REL-002 only after that merge. |
| Tag `v0.23.0` and `gh release create` have not run. Latest GitHub release on 2026-11-04 is `v0.17.0`. The rehearsal ran on macOS and stopped before creating the release. | REV-002; EVAL-002; EVAL-005; REQ-REL-003; REL-003 | The corrected rehearsal passed its suite. The real `ubuntu-latest` job and the GitHub write are unproven, so a first-run failure is plausible. | No `soft_foundry-0.23.0.gem` is published. Adopters who update stay on whatever GitHub still calls latest. | This judgment, as an open release condition | Tag the merged commit `v0.23.0`. Confirm the workflow attaches `soft_foundry-0.23.0.gem`. Confirm REL-003 from that release. |
| `soft-foundry update --yes` has not installed 0.23.0 on a real machine. The rehearsal stubbed GitHub. Inside `bundle exec`, `version` can print the worktree's 0.23.0 while the installed gem is still 0.22.0, and 0.22.0 has no `phase_seal.rb`. | REV-002; EVAL-003; EVAL-F-003; EVAL-005; REQ-REL-004; REL-004 | Certain until the command is run outside `bundle exec` against the real release. | An adopter on 0.22.0 who updates today stays on 0.22.0. A check run inside `bundle exec` can report 0.23.0 for the wrong tree. | This judgment, as an open release condition | After the GitHub release exists, run `soft-foundry update --yes` outside `bundle exec`. Confirm the installed gem is 0.23.0 and contains `lib/soft_foundry/phase_seal.rb`. Confirm REL-004 from that install. |

`change close` refuses while REL-002, REL-003, or REL-004 is unconfirmed. `change release` copies those three and still requires one extra `--item` whose id is not one of them.

## Accounted for, and not left open

| Item | Disposition |
| --- | --- |
| REV-001 and EVAL-F-001 at review time | The six waived directories and the optional pending directories were untracked, so a clean checkout failed `handoff present`. Commit `72cc1e9` adds those untouched pending templates. A clean checkout of that commit fails only because `14-judgment/handoff.yml` is absent. The seal of this phase supplies it. The push rule above is what remains. |
| REV-003, VER-002, EVAL-F-004 | AC-001 is the specify scaffold. Specify is waived, the scenario was never written, and the criterion names REQ-001 rather than a release requirement. Set aside in `evidence.yml` `criteria_not_covered`. |
| VER-001 | `gem build` warns that the gemspec has no license and no homepage. The gem still builds. The warnings are on `main`'s gemspec. Intake forbids `gem push`. |
| EVAL-F-005 | `help` prints usage and exits 1. `PhaseRunnerTest` and `ProcessesTest` failed in a rehearsal whose `PATH` and `HOME` differed from a GitHub runner, and passed once those were corrected. The guard refuses a double-quoted leading tilde. None of these come from the version constant. |
| Attack waived | Low risk, rationale recorded, no new surface in the diff. Security review conforms. |
| Documentation, FAQ index, observability, remediation | Optional and pending. No new document, metric, or code fix is owed for this constant. Their handoffs are in the judged commit. |
| Learn waived | Low risk. The release-path failure EVAL-004 found is recorded in evaluation and closed for the record layout by `72cc1e9`, with the remaining work in the table above. |
