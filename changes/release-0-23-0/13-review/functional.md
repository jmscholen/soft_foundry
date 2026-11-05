# Functional Review

## Scope reviewed

HEAD `6ef1950a3ea79270fb650c0b26866092cd1e982d` (tree `a02f60426a2e744a97d88675417707fc47fa5dcd`). The application diff against `main` is one line: `lib/soft_foundry/version.rb`, `VERSION` from `0.22.0` to `0.23.0`. `soft_foundry.gemspec` already sets `spec.version = SoftFoundry::VERSION`. `Gemfile.lock` is gitignored and is not in the release commit.

Requirements are REQ-REL-001 through REQ-REL-004 in `00-intake/request.md`. Specify, plan, and attack are waived. Verification is sealed at `f6d6dc23e8e3624a45e397ac579d5c416260acaa` (suite tree `3c50e183e994853d3f0ff581bd02c39fc64e005f`: 902 runs, 6653 assertions, 0 failures). Evaluation is sealed at `16bd5f7e0e036f0be98cad675b1c341f9f15d907`. Commits after the version bump add only this change record. Manifest digests for `06-verification/evidence/version.txt` and `07-evaluation/evidence/end-state-ci.txt` match the files.

Rules loaded with the waived discovery's profile (`.ai/repository.yml`: Ruby, Minitest, GitHub Actions, no framework, no database, no IaC tool, no `access_control`): `.ai/rules/general.md`, `architecture.md`, `ruby.md`, `security.md`, `errors.md`, `dependencies.md`, `git.md`, `testing.md`, `observability.md`, `learned.md`. Accessibility, policy, and infrastructure are in their own files.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | major | untracked phase directories; `lib/soft_foundry/gate.rb` `evaluate_observed`; `.github/workflows/ci.yml` | At this HEAD the only tracked handoffs are `00-intake`, `05-implementation`, `06-verification`, and `07-evaluation`. `phase seal` commits the phase it finishes and `metadata.yml`. A clean checkout therefore has no `handoff.yml` for `01-discovery`, `02-specification`, `03-threat-model`, `04-plan`, `08-attack`, `09-remediation`, `10-user-documentation`, `11-faq-index`, `12-observability`, `15-learning`, and, until they are sealed, `13-review` and `14-judgment`. The gate returns `handoff present` fail when the file is missing, before it reads `skipped_phases` or a pending status. The worktree hides this because the scaffold is on disk. EVAL-004 recorded it: a clean checkout of `16bd5f7` exits 2, and `end-state-ci.txt` shows exit 2 when the six waived directories are the ones still absent and exit 0 once they are added. The pull-request workflow runs `bundle exec rake ci`, which is `soft-foundry ci`. | A pull request from a commit that still lacks those directories runs `.github/workflows/ci.yml` on `ubuntu-latest`. `soft-foundry ci` exits 2. REQ-REL-002 cannot merge on a green check. Sealing review and judgment does not add the waived directories, nor an optional phase that stays pending. | REQ-REL-002; `lib/soft_foundry/gate.rb` handoff present |
| REV-002 | major | `07-evaluation/journeys.yml` EVAL-002, EVAL-003, EVAL-005 | REQ-REL-001 is met (below). REQ-REL-002, REQ-REL-003, and REQ-REL-004 are not. EVAL-002 rehearses `.github/workflows/release.yml` on macOS, at HEAD, and stops before `gh release create`. EVAL-003 installs a locally built gem through the 0.22.0 updater with GitHub's response stubbed; the real read-only check still sees latest `v0.17.0`. EVAL-005, the merge, the tag, the GitHub release, and `update --yes` on the real machine, has not run. | A judgment that treats the rehearsals as meeting REQ-REL-002, REQ-REL-003, and REQ-REL-004 can close the change while GitHub's latest release is still `v0.17.0`. An adopter on 0.22.0 who runs `soft-foundry update --yes` stays on 0.22.0. That gem has no `lib/soft_foundry/phase_seal.rb` (`update-path.txt`: `0.22.0 has phase_seal.rb: 0`). Carry the three as open items on `change release`. | REQ-REL-002, REQ-REL-003, REQ-REL-004 |
| REV-003 | major | `02-specification/acceptance-criteria.yml` AC-001 | The specify phase is waived. Its scaffold still defines criterion AC-001 with unfilled fields and `requirements: [REQ-001]`. No verification check and no journey names AC-001. `acceptance_ids` returns every id in that file whenever the file exists, including while the specify handoff is pending. Committing the directory so REV-001's clean checkout can pass therefore puts AC-001 in front of the judgment gate. | `gate judge` fails `criteria covered` on AC-001. The record cannot be judged until `14-judgment/evidence.yml` sets AC-001 aside under `criteria_not_covered` with a reason of at least two words. The waiver is the reason: the criterion was never specified. | `lib/soft_foundry/gate.rb` `criteria_check`; EVAL-F-004 |

## Requirement results

REQ-REL-001 is met. `VERSION` is `"0.23.0"`. `ruby -Ilib exe/soft-foundry version` prints `0.23.0` (`evidence/version.txt`, digest matches the manifest). `gem build` produced `soft_foundry-0.23.0.gem` and warned about a missing license and homepage; those warnings are on `main`'s gemspec too, and the gem built. The installed rehearsal gem reports `0.23.0` (`route-sweep.txt`). `Manifest::VERSION` and `Snapshot::VERSION` are format versions, both `1`, and are separate constants.

REQ-REL-002, REQ-REL-003, and REQ-REL-004 are open. See REV-001 and REV-002.

The tag step in `release.yml` compares `v` plus `soft-foundry version` to `GITHUB_REF_NAME`. The rehearsal accepted `v0.23.0` and refused `v0.22.0` (`tag-path-first-run.txt`). The first suite run in that rehearsal failed 5 tests because `PATH` contained `codex` and `HOME` was under a symlink; the rerun with neither condition passed 902 runs, 0 failures (`tag-path-suite-rerun.txt`). That rerun is the evidence for the test step. It ran on macOS, not `ubuntu-latest`.

`Updater::GEM_NAME` is `soft_foundry-<version>.gem`, which is the name `gem build` writes and the name `gh release create soft_foundry-*.gem` attaches. The rehearsal's built gem matched the tree's `lib` (0 files different) and contained `phase_seal.rb` (8369 bytes, the same size as `lib/soft_foundry/phase_seal.rb` at this HEAD).

CHECK-004 (`soft-foundry ci` in this worktree) passed because the untracked directories are present here. It does not contradict REV-001.

No check records a `red_commit`. The change is a chore. `.ai/rules/testing.md` asks for a RED commit on a feature, fix, or refactor.

## Conformance

The version constant conforms to REQ-REL-001, `.ai/rules/general.md`, and `.ai/rules/ruby.md`. The release does not yet conform to REQ-REL-002, REQ-REL-003, or REQ-REL-004. REV-001, REV-002, and REV-003 are major and go to judgment. None is blocking: remediation cannot commit the other phase directories, and it cannot push, merge, or tag.
