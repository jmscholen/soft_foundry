# Final Judgment

## Outcome
APPROVED_WITH_RESIDUAL_RISK

## Commit judged
`72cc1e95d224fdcf2421e275dd68912f9df6f850`

The application diff against `main` is one line. `lib/soft_foundry/version.rb` sets `VERSION` to `0.23.0`. No file under `lib/`, `exe/`, `test/`, `spec/`, `infra/`, or `.github/` changed between verification commit `f6d6dc23e8e3624a45e397ac579d5c416260acaa` and this commit. The version blob is `83712d1e499f73edb8fd49a72b780577ed1b6a9f` at both.

## Requirements status
The requirements are REQ-REL-001 through REQ-REL-004 in `00-intake/request.md`. Specify is waived. `02-specification/requirements.yml` is still the unfilled scaffold.

| ID | Result |
| --- | --- |
| REQ-REL-001 | Met. `SoftFoundry::VERSION` is `0.23.0`. CHECK-005 prints `0.23.0`. CHECK-006 built `soft_foundry-0.23.0.gem`. CHECK-007 shows that single line against `main`. EVAL-001's installed rehearsal gem reports `0.23.0`. |
| REQ-REL-002 | Open. No pull request exists for `change/release-0-23-0`, and the branch is not on `main`. Carried as REL-002. |
| REQ-REL-003 | Open. GitHub's latest release, queried 2026-11-04, is `v0.17.0`. Tag `v0.23.0` and `gh release create` have not run. EVAL-002 rehearsed `.github/workflows/release.yml` on macOS and stopped before that step. Carried as REL-003. |
| REQ-REL-004 | Open. A real `soft-foundry update --yes` has not installed 0.23.0. EVAL-003 stubbed GitHub and showed that 0.22.0's updater installs a local 0.23.0 gem containing `phase_seal.rb` (8369 bytes, tree `lib` diff of 0 files). The same transcript's read-only check still sees latest `v0.17.0`, and `0.22.0 has phase_seal.rb: 0`. Carried as REL-004. |

## Verification
Complete, and current for this commit's code. Handoff commit `f6d6dc23e8e3624a45e397ac579d5c416260acaa`. Seven checks, all pass. Full suite on tree `3c50e183e994853d3f0ff581bd02c39fc64e005f`: 902 runs, 6653 assertions, 0 failures, 0 errors, 0 skips. The gate on a clean checkout of the judged commit passes this phase, and warns that AC-001 is named by no check. This judgment sets that scaffold criterion aside.

CHECK-004 (`soft-foundry ci` in the worktree) passes because the phase directories exist on disk. It is the worktree result. The clean-checkout result is under Evaluation.

## Evaluation
Complete, and current for this commit's code. Handoff commit `16bd5f7e0e036f0be98cad675b1c341f9f15d907`.

| Journey | Result at that commit | What it establishes |
| --- | --- | --- |
| EVAL-001 | pass | Installed 0.23.0 gem, route sweep, guard reinstalled, `doctor` exits 0 |
| EVAL-002 | pass | Tag-workflow rehearsal, including a corrected full suite of 902 runs and 0 failures. macOS, and `gh release create` was not run |
| EVAL-003 | pass | Updater rehearsal with GitHub stubbed for the 0.23.0 asset. Real read-only check still sees `v0.17.0` |
| EVAL-004 | fail | Clean checkout of the evaluation commit exits 2. Waived phase directories were untracked |
| EVAL-005 | blocked | Merge, tag, GitHub release, and `update --yes` wait on this judgment and the person's go-ahead |

Commit `72cc1e95d224fdcf2421e275dd68912f9df6f850` adds the untouched pending templates for phases 01, 02, 03, 04, 08, 09, 10, 11, 12, and 15. A clean checkout of that commit, run here as `ruby -Ilib exe/soft-foundry ci --change release-0-23-0`, fails on one check: `14-judgment/handoff.yml` is missing. Intake, implementation, verification, evaluation, and review pass. Waived and optional phases are pending with their handoffs present. `phase seal` of this phase is the commit that adds this directory. EVAL-004 stays a fail in the evaluation record. This judgment records the later commit. It does not rewrite the journey.

## Attack
Waived. `metadata.yml` names attack in `skipped_phases` with a rationale, and low risk may waive it. The handoff is pending. The diff is a string literal. Security review found no new input, credential, network call, path, or authorization decision. The release workflow's token use is unchanged. This judgment uses that review and the waiver. It did not re-open the gate-hardening attack record.

## Documentation
`10-user-documentation` and `11-faq-index` are optional and pending. The user-visible change is the version token on lines that already exist. README already documents `update` and `update --yes`. Both directories are in the judged commit, so a clean checkout has the handoffs. No new document is required for REQ-REL-001.

## Observability
`12-observability` is optional and pending. `surfaces.observability` is false. The diff adds no runtime failure mode. The pull-request workflow already exits non-zero when `ci` fails, and the tag step already exits 1 when the tag disagrees with `VERSION` (rehearsed: `v0.22.0` against `0.23.0`). The directory is in the judged commit. No alarm or dashboard is owed.

## Review findings
Review is complete at handoff commit `6ef1950a3ea79270fb650c0b26866092cd1e982d`, sealed as `977d8ee`, current for code, and stamped as a fresh session on xAI. Implementation ran on Anthropic. Remediation has not run. No blocking findings. Three majors:

- REV-001. At review time a clean checkout failed `handoff present` for every untracked phase directory. Commit `72cc1e9` puts those directories in history. The remaining absence is this phase directory, which the seal of this phase commits. Closed as a record defect. REL-002 still says to push the seal, so the pull request is not opened from `72cc1e9` alone.
- REV-002. REQ-REL-002, REQ-REL-003, and REQ-REL-004 are open. Accepted here as residual risk and listed under `undischarged`, so `change close` refuses until a person confirms each id.
- REV-003. AC-001 is set aside in `evidence.yml`. Specify was waived. The criterion is the scaffold. Its scenario was never written, and it names REQ-001, which is not a release requirement.

Architecture, security, accessibility, policy conformance, infrastructure, and operations conform, on the terms in those review files. Policy text changes required: none. `surfaces.policy` and `surfaces.accessibility` are false.

## Residual risk
The residual is the unpublished release. REL-002, REL-003, and REL-004 in `evidence.yml` are the open conditions. `residual-risk.md` weighs them. Gemspec license and homepage warnings, and EVAL-F-005, are accounted for there and are not conditions of this release.

Remediation is the wrong loop for what remains. Its write set is application, test, and infrastructure code plus `09-remediation/`. It cannot commit other phase directories, and it cannot push, merge, or tag. Those steps are the person's, after this judgment.

## What the person does next
1. Let `phase seal` commit this directory.
2. Push that commit and open the pull request. A clean checkout of `72cc1e9` without this directory fails `ci`.
3. `soft-foundry change release` copies REL-002, REL-003, and REL-004 out of `undischarged`. The command also requires one `--item ID=DESCRIPTION` whose id is different from those three.
4. Merge. Tag `v0.23.0` on the merged commit. Confirm the GitHub release asset is `soft_foundry-0.23.0.gem`.
5. Outside any `bundle exec` session, run `soft-foundry update --yes`. Confirm the installed gem is 0.23.0 and contains `lib/soft_foundry/phase_seal.rb`.
6. Confirm REL-002, REL-003, and REL-004 only after those events, with `change close --confirm`, a pull-request comment `CONFIRMED: <id>`, or `change discharge` once the change is released.

Learn is waived at low risk. `next` stays `learn` so the runner can step over that waiver.
