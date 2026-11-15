# Evaluation Results

Commit SHA: 0c213b4c26aca56a5a4f686bfc4ebf0018be4297. Its code is identical to the implementation commit a37d580: `lib/`, `exe/` and `.ai/` have no diff between them.

Size: `full_route_sweep`, from `soft-foundry change size --phase evaluate` ("no scope declared"). Every command the change touches was driven through the real CLI, plus a `check` smoke run (see `evaluation-plan.md`).

## Journey outcomes
| Journey | Criteria | Tier | Result | Evidence |
| --- | --- | --- | --- | --- |
| EVAL-001 | AC-005 | must | pass | evidence/eval-001-tiers.txt |
| EVAL-002 | AC-006 | must | pass | evidence/eval-002-must-cap.txt |
| EVAL-003 | AC-007 | must | pass | evidence/eval-003-approval.txt |
| EVAL-004 | AC-002 | must | pass | evidence/eval-004-cap-refusal.txt, eval-004a-round-count-wording.txt |
| EVAL-005 | AC-003 | should | pass | evidence/eval-005-auto-reopen.txt |
| EVAL-006 | AC-004 | must | pass | evidence/eval-006-cap-decision.txt |
| EVAL-007 | AC-008 | must | pass | evidence/eval-007-tier-coverage.txt |
| EVAL-008 | AC-009 | must | pass | evidence/eval-008-person-checks-release.txt |
| EVAL-009 | AC-010 | must | pass | evidence/eval-009-blocked-basis.txt |
| EVAL-010 | AC-011 | should | pass | evidence/eval-010-outside-change.txt |
| EVAL-011 | AC-014, AC-015 | should, must | pass | evidence/eval-011-docs-only.txt |
| EVAL-012 | AC-013 | should | pass | evidence/eval-012-docs-sizing.txt |
| EVAL-013 | AC-012 | should | pass (as narrowed by DEV-004) | evidence/eval-013-default-waivers.txt |
| EVAL-014 | AC-001, AC-018 | must | pass | evidence/eval-014-legacy-record.txt |
| EVAL-015 | AC-018 | must | pass (smoke only) | evidence/eval-015-smoke.txt |
| EVAL-016 | AC-019 | should | pass | evidence/eval-016-no-color-ascii.txt |

Must criteria with a journey: AC-001, 002, 004, 005, 006, 007, 008, 009, 010 and 015. AC-017 (CHECKS entries, eval cases and documentation lines) and AC-018 (the full suite and `ci`) are repository inspections, not user journeys. They rest on verification's CHECK-001, CHECK-005 and CHECK-007. EVAL-014 and EVAL-015 add user-level smoke for AC-018: legacy outcomes unchanged and `check` clean. They do not replace the suite run. AC-016 (skill text) is likewise left to verification's CHECK-008.

Details worth carrying:
- **EVAL-004:** before the refused reopen, both rounds were sealed by `phase seal remediate` itself (two `Record c1 remediate` commits). After the refusal every handoff is byte-identical, and the only change to metadata.yml is the status line.
- **EVAL-005:** remediation is not commit-bound, so the automatic reopen that reaches it comes from a stale verify (DEV-001). A stand-in `claude` on PATH confirmed no session started.
- **EVAL-011:** the transcript has one discarded attempt. That attempt committed the phase files by hand, so the seal reported "already sealed". It is followed by the corrected runs: README.md committed, the phase left to the seal, which succeeds; lib/ committed, which is refused.
- **EVAL-013:** specify is not a default waiver. This is DEV-004, the maintainer's decision. AC-012's `then` still lists specify (VER-002).

## Failures
None. No journey failed and none was blocked.

## Advisory findings (outside the must criteria; never a reason this change fails)
- **EVA-001:** the follow-up advisory is printed for any finding marked `outside_change`, even when the outside-change check rejects it. Two cases:
  - With `paths: [lib/app.rb]`, a path the change modified, the gate fails ("it is this change's finding"). The advisory below it still says "REV-001 (13-review) concerns code outside this change".
  - With `follow_up` missing, the advisory reads "carried to (no follow_up named)".
  (eval-010)
- **EVA-002:** the round-cap message says "has sealed N remediation rounds", but N is the larger of the seal commits and the reopen entries that reset a complete remediation. In an exploratory run, remediation was completed twice and never sealed (no `Record c1 remediate` commit existed), and the seal was still refused as "has sealed 2 remediation rounds" (eval-004a). Past the limit it also reads "has sealed 3 remediation rounds, the limit in .ai/workflow.yml (remediation.max_rounds: 2)" (eval-006). Wording like "has run N rounds (limit 2)" would be accurate in both cases. The behaviour itself is the intended conservative count (THREAT-002).
- **EVA-003:** `phase reopen` on a change that is already parked says only "c1 is awaiting_human ... a person must record the decision under human_decisions". Unlike the first refusal, it does not repeat the boundary, the rounds value or the three decisions. The person can still find them in the `change status` advisory (eval-005, eval-006).
- **EVA-004:** on a new-rules specification with no must criteria, `must criteria approved` still fails and asks for "criteria: [], decision: approved" (eval-001). It may be intended, but the specification and documentation should say so.
- **EVA-005:** the blocked-basis check accepts any must id in `blocked_by` and does not confirm that the criterion is unmet. This is consistent with the gate's structure-only scope. Judgment and review should read `blocked_by` against the evidence, not trust a pass.
- **EVA-006:** the outside-change check also requires `paths:` on the finding and fails "names no paths" without it. REQ-009 and AC-011 mention only `follow_up`. Documentation and review should confirm the user documentation states `paths` (this phase may not read DOCS).
- **EVA-007 (accessibility):** the cap refusal is one line of about 520 characters. It survives NO_COLOR and ASCII stripping, but splitting it into a short outcome line and one line per decision would read better on screen readers and narrow terminals.

## Accessibility observations
Command-line surface only; no visual UI changed.
- **Keyboard:** every journey was typed commands with no prompts or pointer.
- **Colour:** every run had `NO_COLOR=1`, and the transcripts contain no escape sequences.
- **ASCII stripped:** the only non-ASCII characters were the existing ✓ and ✗ glyphs. With them stripped, `pass`, `fail`, `warn` and `skip`, the prefixes (`soft-foundry:`, `c4: cannot seal remediate:`, `phase reopen:`) and the next action survive on every new line exercised (eval-016).
- **Error identification:** refusals name the criterion ids, the round count, the offending path and the person's action.
- **Readability:** see EVA-007 on line length.
