# Attack Results

Commit SHA: 53341d576b69b6f708f2fb6786b497bc00c3a0d7

Size: `full_route_sweep` (`soft-foundry change size scoped-verification --phase attack`; this record declares no scope, so the whole repository is sized full). Code paths were clean (only this change's handoff and metadata, edited by the runner, were modified). Evidence: `evidence/attack.rb`, `evidence/attack2.rb` and `evidence/attack_lib.rb` drive the real CLI (`ruby -Ilib exe/soft-foundry`) against throwaway repositories; the output is `evidence/transcript.txt` and `evidence/transcript2.txt`.

## Authorization envelope
Local, ephemeral, synthetic data, loopback only, no destructive action outside the temp directories; see `cases.yml` and `attack-plan.md`. No provider refusal occurred.

Transcript headings in the drivers use their own numbering; this table maps case IDs to the transcript sections: ATTACK-001 to 006 are sections 001 to 006 of `transcript.txt`; ATTACK-007 is its section 007; ATTACK-008 is its section 009 (injection); ATTACK-009 is its section 010 (resource); ATTACK-010 is its section 011; ATTACK-011 is section 012 of `transcript2.txt` (the first attempt in `transcript.txt` section 012 could not start the server and is superseded); ATTACK-013 to 016 are sections 013 to 016 of `transcript2.txt`.

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
| ATTACK-013 rename out of an access-control or claimed path | THREAT-006 | violated | transcript2.txt |
| ATTACK-014 repoint git.branch to hide staleness | THREAT-001 | violated | transcript2.txt |
| ATTACK-015 active record with ** hides cross-record change | THREAT-003 | violated | transcript2.txt |
| ATTACK-016 case-folded citation slug | THREAT-009 | violated | transcript2.txt |

There is no ATTACK-012: it was the first browser attempt and is folded into ATTACK-011.

## Violations found
Four, none repaired here (this phase reports).

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

## Not exercised
A real browser rendering the page (keyboard, focus, screen reader); the two-process race of a concurrent gate run during a commit; a network remote; Windows path separators.
