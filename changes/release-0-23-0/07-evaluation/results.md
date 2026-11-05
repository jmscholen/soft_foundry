# Evaluation Results

Commit SHA: 16bd5f7e0e036f0be98cad675b1c341f9f15d907
Size: `full_route_sweep`

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 every route on the installed gem | REQ-REL-001 | pass | `evidence/route-sweep.txt`, `evidence/doctor-with-guard.txt` |
| EVAL-002 tag workflow rehearsal | REQ-REL-003 (rehearsal only) | pass | `evidence/tag-path-first-run.txt`, `evidence/tag-path-suite-rerun.txt` |
| EVAL-003 update from the real 0.22.0 | REQ-REL-004 (rehearsal only) | pass | `evidence/update-path.txt` |
| EVAL-004 `ci` on a clean checkout | REQ-REL-002 | **fail** | `evidence/clean-checkout-ci.txt`, `evidence/end-state-ci.txt` |
| EVAL-005 the real merge, tag, release and update | REQ-REL-002, 003, 004 | blocked | none: not reached |

**No requirement but REQ-REL-001 is proven.** EVAL-002 and EVAL-003 are rehearsals; REQ-REL-002, 003 and 004 are met only by EVAL-005, and REQ-REL-002 also needs EVAL-004 fixed.

## Failures

### EVAL-004: the branch fails `ci` once pushed
`soft-foundry ci` passes in the worktree and exits 2 on a clean checkout of the same commit. The worktree passes only because the phase directories exist there untracked.

`phase seal` stages only its own phase directory and `metadata.yml`, so sealing the remaining phases leaves the six waived ones (01, 02, 03, 04, 08, 15) uncommitted. Tested on a clean checkout:

| State | `ci` | Failing checks |
| --- | --- | --- |
| HEAD as committed | exit 2 | 13 `handoff present`, 1 `predecessor complete` |
| Plus the phases that will be sealed | exit 2 | 6 `handoff present`, 1 `predecessor complete`: all the waived phases |
| Plus the six waived directories | exit 0 | none |

In the last two states the later phases were still working files, not sealed output, so this shows what the waived directories cost, not that the finished record passes. The fix is a record commit, not a code change: add the six directories before pushing. This skill may not commit, so it is handed on as EVAL-F-001. Earlier waived records have those directories tracked because they were committed by hand; `git log` shows them in hand-written commits.

### EVAL-002 first run: 5 suite failures, caused by the rehearsal
The first run of the suite ended 902 runs, 5 failures. All five were traced to the scratch setup, and the rerun with it corrected passed: 902 runs, 6653 assertions, 0 failures, 0 errors, 0 skips.
- `ProcessesTest`: HOME was under `/tmp`, a symlink to `/private/tmp`. Passed once HOME was a resolved path.
- `PhaseRunnerTest` (four tests): the PATH had `codex` but not `claude`, so review chose `codex`. The rerun's PATH has neither, as on a GitHub runner.

The first run's transcript shows only the last 25 lines, so failures 1 and 2 are named by the isolated rerun of those two test files, not by that transcript, and that isolated rerun was not kept as evidence. The clean full rerun is what supports the result.

## Limits of this evidence
- EVAL-002 ran on macOS with Ruby 3.3.1, not on `ubuntu-latest`, and against HEAD, not the merged commit. `gh release create` and the `GITHUB_TOKEN` write permission were not run.
- EVAL-003 stubs GitHub's response and the download for v0.23.0, because that release does not exist. The download path was run for real on v0.17.0 only.
- EVAL-001 did not run `phase run` for real, `--panel`, `eval --live`, or `update --yes` on the real machine. `phase run evaluate attack --parallel --dry-run` was refused for an unmet predecessor, which is correct, so the parallel dry run's success path was not reached.
- `ci` in EVAL-001 ran from a change branch in a scratch repository.

## Sweep results read
`route-sweep.txt` records 55 as expected and 5 `UNEXPECTED`, a raw count kept as the script printed it. All five were wrong expectations in the script, not defects:
- `doctor` exit 2: the sweep had just uninstalled the guard, and the policy is block. With the guard installed it exits 0 (`doctor-with-guard.txt`).
- `gate all` exit 0 and `change request-discharge` exit 0: nothing had failed, and nothing was undischarged. Neither reached GitHub.
- `phase run evaluate attack --parallel --dry-run` exit 1: the refusal described above.
- `help` exit 1: `help` is not a command, so it prints usage and exits 1, while no arguments exits 0. Handed on as EVAL-F-005.

## Accessibility observations
N/A: `surfaces.accessibility` is false, and only the version text a person reads changed.
