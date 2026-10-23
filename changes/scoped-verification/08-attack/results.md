# Attack Results

Commit SHA: 7ca42a176a3a79baa30e58063dcaeabe1908661a

Size: `full_route_sweep` (`ruby -Ilib exe/soft-foundry change size --phase attack`, the checkout's own code since the installed binary predates the change; this record declares no scope, so the whole repository is sized full). Code paths were clean (only this change's handoff and metadata, edited by the runner, were modified). This is the third rerun, after the REV-001/REV-002 remediation (84b9035; `Scope.tip_for` now takes the evidence commit): all drivers were run again against the checkout and the transcripts replaced, and a fourth driver (`evidence/attack4.rb`, `transcript4.txt`) probes the new measure rule. Evidence: `evidence/attack.rb`, `evidence/attack2.rb` and `evidence/attack_lib.rb` drive the real CLI (`ruby -Ilib exe/soft-foundry`) against throwaway repositories; the output is `evidence/transcript.txt` and `evidence/transcript2.txt`.

## Third rerun (after the REV-001/REV-002 remediation)
Size: `full_route_sweep` (`ruby -Ilib exe/soft-foundry change size --phase attack`; no scope declared). Code paths were clean at HEAD `7ca42a176a3a79baa30e58063dcaeabe1908661a`; only this change's handoff, metadata and attack evidence were modified.

- ATTACK-017 is denied: a branch created at the evidence commit is no longer the measure, so `lib/a/x.rb` landing on main stales the scoped and the unscoped record, and the whole verify gate fails with or without a recorded size and run. The scoped gate no longer fails incidentally on the sizing base.
- ATTACK-019 is still violated, as the remediation summary says it would be. `git.branch: frozen` is recorded before the branch exists, evidence is recorded, the phases are completed, and `frozen` is then created at the phases-complete commit. That tip strictly descends from the evidence commit, so `Scope.tip_for` treats it as the branch the record lives on and measures there; code landing on main afterwards is not counted, and with a recorded size and a run of the evidence tree the whole `gate verify` passes for scoped and unscoped records. ATTACK-020 repeats it with the scope declared in the evidence commit; same result. This is ATTACK-F-007 narrowed, not closed: a branch cut after the evidence commit can no longer be the evidence commit itself, but one cut at any later commit before the code lands still hides it. Fix direction: require the recorded branch tip to equal or descend from HEAD, or to be HEAD's branch, whenever HEAD is not an ancestor of it and the branch did not exist at the evidence commit; or compare the branch tip with a commit recorded in the handoff rather than with ancestry alone; or accept the residual explicitly for review and judgment.
- ATTACK-021 (control): a change stacked under another keeps its own branch as the measure; in-scope code on the branch above is not counted (by design), and a commit on the record's own branch stales it. Works as the remediation states.
- ATTACK-014, 013, 016 stay denied; ATTACK-015 is unchanged (accepted residual of MIT-003); ATTACK-018's scalar `git` still exits 1 with "String does not have #dig method" (fails closed, robustness only). ATTACK-001 to 011: the normalized transcript differs from the previous run only in random hashes and in the intended wording of the size line (the cause is now named and the "scope matches no changed file" advisory no longer fires in that case); no regression found.
- REV-002 (a claimed path does not enlarge a record's size) is the confirmed behaviour; ATTACK-015 shows its cost.

Also open: ATTACK-F-007 (narrowed, ATTACK-019/020), ATTACK-F-003, ATTACK-F-008, ATTACK-F-005.

## Authorization envelope
Local, ephemeral, synthetic data, loopback only, no destructive action outside the temp directories; see `cases.yml` and `attack-plan.md`. No provider refusal occurred.

Transcript headings in the drivers use their own numbering; this table maps case IDs to the transcript sections: ATTACK-001 to 006 are sections 001 to 006 of `transcript.txt`; ATTACK-007 is its section 007; ATTACK-008 is its section 009 (injection); ATTACK-009 is its section 010 (resource); ATTACK-010 is its section 011; ATTACK-011 is section 012 of `transcript2.txt` (the first attempt in `transcript.txt` section 012 could not start the server and is superseded); ATTACK-013 to 016 are sections 013 to 016 of `transcript2.txt`; ATTACK-017 to 019 are in `transcript3.txt`; ATTACK-020 and 021 are in `transcript4.txt`.

## Case outcomes
| Case | Threat | Result | Evidence |
| --- | --- | --- | --- |
| ATTACK-001 declaration narrowing | THREAT-001 | denied | transcript.txt |
| ATTACK-002 blind and hostile declarations | THREAT-002 | denied | transcript.txt |
| ATTACK-003 cross-record scope abuse (closed, malformed, unreadable siblings) | THREAT-003 | denied | transcript.txt |
| ATTACK-004 forged and abusive full-suite records | THREAT-004 | denied | transcript.txt |
| ATTACK-005 reuse over dirty, untracked, ignored files | THREAT-005 | denied | transcript.txt |
| ATTACK-006 undersized checks | THREAT-006 | denied | transcript.txt |
| ATTACK-007 git failure as no change | THREAT-007 | denied | transcript.txt |
| ATTACK-008 injection through slugs, options, YAML | THREAT-009 | denied | transcript.txt |
| ATTACK-009 resource exhaustion | THREAT-010 | denied | transcript.txt |
| ATTACK-010 structural pass read as proof | THREAT-011 | denied | transcript.txt |
| ATTACK-011 markup and the browser view | THREAT-012 | denied | transcript2.txt |
| ATTACK-013 rename out of an access-control or claimed path | THREAT-006 | denied (fixed) | transcript2.txt |
| ATTACK-014 repoint git.branch after the evidence commit | THREAT-001 | denied (fixed) | transcript2.txt |
| ATTACK-015 active record with ** hides cross-record change | THREAT-003 | violated | transcript2.txt |
| ATTACK-016 case-folded citation slug | THREAT-009 | denied (fixed) | transcript2.txt |
| ATTACK-017 git.branch recorded in the evidence commit, branch at it | THREAT-001 | denied (fixed by REV-001) | transcript3.txt |
| ATTACK-018 malformed git metadata, delete and revert | THREAT-007 | denied (unhandled error on a scalar `git`) | transcript3.txt |
| ATTACK-019 git.branch recorded before the branch exists, created at the phases-complete commit | THREAT-001 | violated (acknowledged residual) | transcript3.txt |
| ATTACK-020 same, scope declared in the evidence commit | THREAT-001 | violated (same cause as ATTACK-019) | transcript4.txt |
| ATTACK-021 control: stacked branch measured on its own branch | THREAT-001 | denied (as designed) | transcript4.txt |

There is no ATTACK-012: it was the first browser attempt and is folded into ATTACK-011.

## Rerun after remediation
ATTACK-013 and ATTACK-016 are denied now: the diff lists both sides of a rename (the source path stales its record and raises the attack size to full_route_sweep), and a citation slug must equal the directory name. ATTACK-014 is only partly fixed (below). ATTACK-015 is unchanged, the accepted residual. Confirmed: a path claimed by another record no longer enlarges a record's verify size, and the size line names a cause when no path is one. No regression was found in ATTACK-001 to 011 (transcript differences are those intended changes and the changed wording).

## Second rerun (after the ATTACK-F-006 remediation)
ATTACK-014 is denied: an edit of `git.branch` after the evidence commit now stales scoped records (`declaration changed: git.branch`) and unscoped ones, and the whole verify gate fails. No regression in ATTACK-001 to 011, 013, 015, 016 (the transcript differences are the intended `git.branch` cause lines plus random hashes). The remediation compares `git.branch` at the evidence commit with now, so it does not cover a value that was already recorded then.

New finding ATTACK-F-007 (moderate, ATTACK-019 and ATTACK-017): a session records `git.branch: frozen` before the evidence commit (no such branch exists yet, so the measure falls back to the worktree), completes the phases, then creates branch `frozen` at the phases-complete commit and lands code on main. `git.branch` is unchanged since the evidence, the tip contains the evidence commit, so `evidence current` measures only up to the tip; with a recorded size and a run of the evidence tree the whole `gate verify` passes for scoped and unscoped records although `lib/a/x.rb` changed after the evidence (transcript3.txt). In ATTACK-017 (branch created at the evidence commit) the scoped gate fails only because sizing uses the plan commit as its base, which `frozen` does not contain, an incidental refusal. Fix direction: measure at the checked-out HEAD unless the recorded branch is HEAD's own branch or its tip equals or descends from HEAD; or require the recorded branch tip to be at or ahead of HEAD.

New finding ATTACK-F-008 (minor, ATTACK-018): a `metadata.yml` whose `git` is a scalar makes `gate verify` exit 1 with `String does not have #dig method` instead of a gate line. It fails closed (no pass), so it is a robustness defect only.

## Violations found
Original findings with current status. ATTACK-013 and ATTACK-016 were fixed and verified; ATTACK-014 (variant) and ATTACK-015 remain open. None repaired here (this phase reports).

New finding ATTACK-F-006 (moderate, the ATTACK-014 variant): the remediation requires a recorded `git.branch` that is not checked out to contain the evidence commit. A branch created at, or behind HEAD after, the evidence commit satisfies that, so repointing `git.branch` to such an ancestor still hides later code changes, for scoped and unscoped records, and with a recorded size and a run of the evidence tree the whole `gate verify` passes (transcript2.txt, ATTACK-014). Fix direction: measure at the checked-out HEAD whenever the recorded branch is not HEAD's own branch, or require the recorded branch tip to equal or descend from HEAD, or treat an edit of `git.branch` after the evidence commit as a stale cause.

ATTACK-013 (moderate). The tool lists changed paths with `git diff --name-only`, which collapses a rename to its destination (`lib/a/moved.rb`) and omits the source (`lib/auth/f.rb`; `--no-renames` lists both). Consequences shown: (a) `change size --phase attack` for a record scoped to `lib/a/**` stays `touched_doors_plus_smoke` after access-control code was moved out of `lib/auth/**`; (b) a record scoped to `lib/auth/**` keeps "evidence current" PASS after its file is renamed into another record's scope; a plain delete stales it. A session can then record `full_at_verify` and a run of the evidence tree and the whole gate passes. Affects sizing (REQ-011, MIT-006) and staleness (REQ-003, THREAT-001's goal). Fix direction for remediation: read the diff without rename detection, and add a test with a rename.

ATTACK-014 (moderate). `metadata.yml` `git.branch` decides which commit "after" is measured on. Pointing it at a branch that exists but lacks the change turns STALE into current, for scoped and unscoped records alike; with a correct size and a run of the evidence tree, `gate verify` reports PASS for a record whose code changed after its evidence. The stacked-branch measurement predates this change, but REQ-013 and MIT-001 name the declarations whose edit must stale evidence, and this one is outside the list although it has the same effect. A non-existent branch correctly falls back to the checked-out worktree. Fix direction: treat an edit to `git.branch` after the evidence commit as a stale cause, or measure at the checked-out HEAD unless the recorded branch contains the evidence commit and is an ancestor-descendant of HEAD.

ATTACK-015 (moderate, accepted by design but the whole gate passes). An active record whose scope is `**` claims every path, so another record's evidence stays current when unrelated code lands, and the verify gate passes in full once the attacker records `full_at_verify` and a run of the evidence tree. Only a non-blocking advisory reports the overlap. `abandoned` and other non-`closed` statuses still count as active. This is the reviewer-judgment residual MIT-003 states; it is reported so review and judgment weigh it, and a stricter option is to refuse (rather than advise) a sibling scope that claims more than a bounded share of the tree or to treat only `status: closed` and `abandoned` as released.

ATTACK-016 (minor). On a case-insensitive filesystem a citation of `ALPHA` resolves to `alpha`'s verification record. The cited run is real and tree-checked, so no forged result passes; the slug is simply not compared exactly. Fix direction: after resolving, require the resolved directory name to equal the slug.

## Residuals recorded, not counted as violations
- A typed `full_suite` with the right tree, any command and outcome `passed` passes; the gate states it is a record, not a test result (REQ-008). Review judges it.
- An ignored file outside the code path groups (for example `config.local`) does not refuse reuse of a cited run (MIT-005's recorded limitation).
- Matching is by path only: a symlink under a scope that points at access-control code sizes as smoke (REQ-015).
- The gate checks recorded size only for verification; a smaller size recorded in evaluation or attack evidence is not refused (REQ-011 limits the refusal to verification).
- An unscoped record does not go stale on a check-sizing policy edit (legacy behaviour; the policy is protected from execution skills).
- Minor wording: when the evidence commit is unknown or a declaration edit is the only cause, the size line prints an empty reason list, `computed size is ... ()`.

## Blocked cases and reason
None.

Also open from this rerun: ATTACK-F-007 (ATTACK-017, ATTACK-019) and ATTACK-F-008 (ATTACK-018). ATTACK-014 as originally raised is fixed.

## Not exercised
A real browser rendering the page (keyboard, focus, screen reader); the two-process race of a concurrent gate run during a commit; a network remote; Windows path separators.
