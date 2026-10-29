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

## Not remediated (carried for review and judgment)
- **ATK-003**: a manual `phase seal` fired while the runner's session is still open yields two consistent `Record` commits. Within TB-3; the runner could fold its stamp into the existing seal. Carried: a design change to the runner, not a refusal.
- **ATK-006**: a deleted or unparseable `.ai/policies/enforcement.yml` defaults the mode to warn, so `fresh session recorded` skips. REQ-014 says "when the mode is block"; the deletion is a commit to a protected path review sees. Carried as the specified behaviour, with the note that `check` could refuse a missing policy.
- **ATK-007**: the seal commits hand edits to `metadata.yml` (risk, `skipped_phases`) and the first seal rewrites the file without the template's comments. Within TB-4; the gate's `waivers permitted` still bounds what a lowered risk may waive. Carried; naming other changed metadata keys in the seal's note is a follow-up.
- **ATK-009** residue: absolute paths in lock and safe-write refusals (pre-existing code paths); `change summary` reports an unparseable `metadata.yml` as `(<unknown>)` (pre-existing); the specification's observability section names `gate --json`, which does not exist (`change status --json` carries the checks; a text error in the locked specification, recorded here rather than edited); MIT-002's promise of a session-id line in the advisory and `change summary` is not implemented (threat-model text, not a requirement); after a killed seal a rerun needs `.git/index.lock` removed by hand (git's own message says so).

## Evidence invalidated
Every commit-bound phase: `06-verification` (sealed at `303a48f`), `07-evaluation` (never completed; its session was killed), `08-attack` (complete at `303a48f`, unsealed). `phase reopen verify --reason …` reset all three to pending before the RED commit (`phase_reopenings` entry, source manual); their files are kept under their directories. `13-review` and `14-judgment` had not run.

## Required reruns
Verification, evaluation and attack, in that order (evaluation and attack in parallel), against the commit this phase's handoff names; then review and judgment.
