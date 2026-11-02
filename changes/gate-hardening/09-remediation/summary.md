# Remediation

## Finding references
From `08-attack/handoff.yml` (attack run at `303a48f`, sealed verification):
- **ATK-001 (major)**, remediated. A recorded phase's `commit_sha` could be rewritten forward after a code change; `commit lineage` and `evidence current` then passed and `phase seal` recorded a second commit with `phase_reopenings` empty (THREAT-003 was closed only backwards).
- **ATK-002 (minor)**, remediated. A seal whose record branch does not exist committed to the checked-out branch and said nothing.
- **ATK-004 (minor)**, remediated. A failed check was acknowledged by substring (`CHECK-1` by a finding about `CHECK-10`).
- **ATK-005 (minor)**, remediated. A `criteria_not_covered` reason of `-`, `n/a`, `.` or one bare word passed, and an id that is not a criterion was accepted silently.
- **ATK-008 (minor)**, remediated. A manifest with an empty `artifacts` list passed on verify, evaluate and attack.
- **ATK-009 (minor)**, one item remediated: a runner stamp of `soft-foundry phase run --fake` passed the prefix match. The remaining accuracy items are carried below.
- **ATK-003, ATK-006, ATK-007** and the rest of ATK-009, carried with reasons under "Not remediated".

## Root cause
- ATK-001: `commit lineage` checked ancestry only (predecessor → this phase → tip), which a forward rewrite satisfies. The structural fact it ignored is that a recorded phase already names a commit in its recorded handoff, and the only recorded way that commit changes is a reopening (`phase_reopenings`).
- ATK-004: the acknowledgement text was joined and searched with `include?`.
- ATK-005: the reason test was "not blank and not the placeholder", and the set-aside ids were not compared with the criteria.
- ATK-008: the manifest check verified each listed artifact and treated an unlisted file as a warning, so an empty list had nothing to verify.
- ATK-002: D1 covered the wrong-branch case and left the missing-branch case silent.
- ATK-009 stamp: `start_with?` where exact names were meant.

## Changes made
GREEN `c30af60`, after RED `4d7392a` (`test/remediation_gate_hardening_test.rb`, six tests, all failing there):
- `lib/soft_foundry/change_record.rb`: `recorded_handoff(phase, git:)` (the handoff at the recorded commit) and `reopened_since?(phase, since, git:)` (a `phase_reopenings` entry resetting the phase with `from_commit` at or after `since`).
- `lib/soft_foundry/gate.rb`: `commit lineage` fails when a recorded phase's on-disk `commit_sha` differs from the recorded one and no reopening followed, naming both SHAs and `phase reopen`; `test results recorded` matches whole ids; `criteria covered` requires a reason of at least two words and refuses an id that is not a criterion; `evidence manifest verified` fails an empty `artifacts` list; `fresh session recorded` accepts exactly the runner's two names (`RUNNERS`).
- `lib/soft_foundry/phase_seal.rb`: a `note:` naming the missing record branch and the branch committed to.
- `test/phase_seal_test.rb`: `test_branch_resolved_false_measures_head` reshaped; its fixture committed a complete handoff and then rewrote its `commit_sha`, which is the ATK-001 attack, so it now completes verification after repointing the branch.

### Found by sealing this phase (second pass)
The first seal of this phase (`c02a761`) set `current_phase` to `review`: `PhaseSeal#advance!` scanned the later phases and ignored the `remediate -> verify` transition in `.ai/workflow.yml`. The phase was reopened (`phase_reopenings`, 16:24Z), the seal now follows a loop phase's `next` transition when that phase is not complete (RED `d6c2748`, GREEN `c5c20b4`, `test_sealing_remediation_returns_the_record_to_verify`), and this phase is sealed again on that commit.

## Not remediated (carried for review and judgment)
- **ATK-003**: a manual `phase seal` fired while the runner's session is still open yields two consistent `Record` commits. Within TB-3; the runner could fold its stamp into the existing seal. Carried: a design change to the runner, not a refusal.
- **ATK-006**: a deleted or unparseable `.ai/policies/enforcement.yml` defaults the mode to warn, so `fresh session recorded` skips. REQ-014 says "when the mode is block"; the deletion is a commit to a protected path review sees. Carried as the specified behaviour, with the note that `check` could refuse a missing policy.
- **ATK-007**: the seal commits hand edits to `metadata.yml` (risk, `skipped_phases`) and the first seal rewrites the file without the template's comments. Within TB-4; the gate's `waivers permitted` still bounds what a lowered risk may waive. Carried; naming other changed metadata keys in the seal's note is a follow-up.
- **ATK-009** residue: absolute paths in lock and safe-write refusals (pre-existing code paths); `change summary` reports an unparseable `metadata.yml` as `(<unknown>)` (pre-existing); the specification's observability section names `gate --json`, which does not exist (`change status --json` carries the checks; a text error in the locked specification, recorded here rather than edited); MIT-002's promise of a session-id line in the advisory and `change summary` is not implemented (threat-model text, not a requirement); after a killed seal a rerun needs `.git/index.lock` removed by hand (git's own message says so).

## Evidence invalidated
Every commit-bound phase: `06-verification` (sealed at `303a48f`), `07-evaluation` (never completed; its session was killed), `08-attack` (complete at `303a48f`, unsealed). `phase reopen verify --reason …` reset all three to pending before the RED commit (`phase_reopenings` entry, source manual); their files are kept under their directories. `13-review` and `14-judgment` had not run.

## Required reruns
Verification, evaluation and attack, in that order (evaluation and attack in parallel), against the commit this phase's handoff names; then review and judgment.

## Second pass: the rerun's findings (ATK-010 to ATK-013, and ATK-006, ATK-007)
The attack rerun at `5db4836` found the first pass's own gap. RED `cf7b76b` (`test/remediation_gate_hardening_two_test.rb`, eight tests, all failing there), GREEN `39d7e4f`.

- **ATK-010 (major), remediated.** `recorded_commit` took the newest commit touching the handoff, so a hand commit of a rewritten `commit_sha` became the record. It now prefers the newest commit whose subject is `Record <slug> <phase>`, the seal's own; a record with no seal commit for the phase (made before `phase seal`) keeps the old rule.
- **ATK-011, remediated.** A reopening licenses a moved `commit_sha` only when some evidence file under the phase directory, other than `handoff.yml`, differs from the record. A structured file that differs only in `commit_sha` counts as unchanged. The old test of the reopen path (`remediation_gate_hardening_test`) now appends a rerun line to `results.md`, as a real rerun would.
- **ATK-012, remediated.** The recorded and on-disk `commit_sha` are compared as resolved commits; the refusal prints both raw strings.
- **ATK-013, remediated.** An id is delimited by not being followed by a word character, `/`, `-` or `.digit`; a reason is a string of at least two distinct words; a manifest whose every file is empty fails. The structure-only limit stays: two different words of no content pass.
- **ATK-006, remediated as a warning.** `check` warns when `policies/enforcement.yml` is missing and says what that costs. It is not an error: older installs lack the file, and REQ-014 states the default.
- **ATK-007, remediated as a note.** The seal names metadata keys other than the ones the tool moves that differ from the committed file, so a hand edit to `risk` or `skipped_phases` is stated at the commit that honours it.

Not remediated, unchanged: ATK-003 (runner design change) and the ATK-009 residue above. Behaviour change worth review: a phase reopened and rerun with byte-identical evidence now fails commit lineage; the fix is a rerun that produces new output.

## Evidence invalidated (second time)
`phase reopen verify` (2026-10-29, reason ATK-010) reset verification (sealed `5db4836`), evaluation, attack (complete, unsealed) and this phase. Their files are kept for the reruns. Required reruns: verify, then evaluate and attack, review, judgment.

## Third pass: the evaluation's findings (EVAL-017, EVAL-018)
Evaluation, run alone at `87d7b8f`, passed 16 of 19 journeys. Two findings were real. RED `a930c57` (`test/remediation_gate_hardening_three_test.rb`, three tests, two failing there), GREEN `c664d12`.

- **EVAL-017, remediated (REQ-036, AC-052).** `gate all` on this record took 3.4 s and 220 git calls against 1.08 s and 60 for the pre-change gem (259 calls, 3.7 s when remeasured at HEAD). Causes: `recorded_commit` ran `git log` twice and parsed the blob twice per use, `repository?` and `head_sha` ran once per check, and ancestry and blob reads repeated. Now the seal commit comes from one `git log`, memoized per phase and HEAD; answers about a commit named by its full hash (exists, ancestor, blob) are memoized for the life of the `Git` object, since they cannot change; HEAD, the branch, branch tips and `repository?` are cached only inside `Git#observing`, which `Gate#evaluate` and `evaluate_all` open, so a later read sees any commit made since. After: 78 calls, 1.3 s, about 1.2 times the 1.08 s baseline.
- **EVAL-018, remediated (REQ-032).** The two lineage failures that gave a reason and no action now end with the `phase reopen` command, or checking out the record's branch.

Behaviour change: a `Git` object no longer re-reads HEAD while a gate run is open. The runner and the seal open none around a session, so a commit made during a session is seen by the seal that follows.

## Evidence invalidated (third time)
`phase reopen verify` reset verification (sealed `87d7b8f`), evaluation (sealed `f0b256b`) and this phase. Required reruns: verify, evaluate, attack, then review and judgment. The evaluation's journeys and driver are kept for the rerun; EVAL-017 should be remeasured.
