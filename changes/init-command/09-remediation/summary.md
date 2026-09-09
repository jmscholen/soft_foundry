# Remediation

## Finding references
- EVAL-F-001 (major, blocking): `init --root` with no value exited 4 with the internal-failure guidance instead of a usage error with exit 1.
- EVAL-F-003 (minor): conflict runs gave no next step.
- EVAL-F-004 (minor): the summary did not name conflicted paths.
- EVAL-F-005 (minor): onboarding's "not configured" lines did not name the environment variable.
- Harness finding surfaced by this loop: the gate's predecessor rule prevented remediation from ever completing after a blocked phase, and stale complete evidence blocked commits through the pre-commit hook.

## Root cause
- EVAL-F-001: the option parser raised `ArgumentError`, and `init`'s catch-all wraps every non-`SoftFoundry::Error` exception as `InternalError`. A usage mistake was therefore classified as a Soft Foundry defect. The classification rule was correct; the parser used the wrong error class.
- EVAL-F-003/004/005: report text was written to the acceptance criteria, which never required guidance, and the evaluation persona for a scripting agent exposed the gap.
- Harness: the predecessor check was strictly linear and had no notion of the remediation loop; the workflow's `transitions` block describes the loop but the gate did not read it.

## Changes made
- `lib/soft_foundry/cli.rb`: `option` raises `TargetError`; on conflicts the report prints a `conflicts:` line naming every conflicted path and a `next:` line describing `git diff`, keeping the file, or committing and rerunning with `--force`.
- `lib/soft_foundry/onboarding.rb`, `lib/soft_foundry/provider.rb`: provider results carry `api_key_env`, and "not configured" names it.
- `lib/soft_foundry/gate.rb`: remediation's predecessor check passes while any earlier phase is `blocked`, naming what it repairs; otherwise the linear rule stands.
- Tests: usage-error classification, conflict report content, and both gate behaviors. 71 runs, 755 assertions locally.
- Not changed: EVAL-F-002 (`init --help`) is left for review to decide whether per-command help is in scope; the evaluation phase's expected outcomes and transcripts are untouched.

## Evidence invalidated
- `06-verification` (was complete at 6df4d15e73d8): its passing evidence no longer describes the code, so its handoff is reset to `pending` and the run is archived under `previous/6df4d15e73d8/`.
- `07-evaluation` (blocked at 6a41afd123ca): stays `blocked` until re-evaluated, because the blockage is the fact remediation answers and the gate uses it to let remediation close. The run is archived under `previous/6a41afd123ca/`. Nothing from either run was deleted, per the no-deleting-failed-results rule.
- `08-attack` never ran and is unaffected.

## Required reruns
Verification, then evaluation, then attack, all against the remediated commit or later. The gate reports `06-verification` as pending until verification completes and will flag it stale again if code changes after that.

## Harness follow-ups for learning
- A `soft-foundry change invalidate <phase>` command should perform the archive-and-reset step this remediation did by hand.
- The gate should read `transitions` from `workflow.yml` instead of special-casing `remediate`.

## Harness follow-up applied after evaluation passed
Once evaluation was re-run and passed, nothing was blocked and the gate fell back to the linear rule, failing remediation on "08-attack is pending" and blocking the commit through the pre-commit hook. The special case above was the wrong model. `workflow.yml` now declares remediation `optional: true` with `after: implement`, the control plane resolves an effective predecessor that honors `after` and skips optional phases that never ran, and `check` validates `after` targets. This is harness code under `${APP}` for this repository, so verification and evaluation evidence at c29509c was archived under `previous/` and reset for a second rerun. Learning should capture that harness fixes discovered mid-change force evidence reruns when the harness and the product share a repository.
