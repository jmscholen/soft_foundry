# Remediation

## Finding references
ATK-001 (major), ATK-002 (minor), ATK-003 (minor) from 08-attack. Not changed: ATK-004 (hand-edited discharge; TB-3 accepts hand edits, recorded as an observation), ATK-005 (documented residuals), ATK-006 (coverage gap, not a defect), EVAL-F1..F4 and VER-002 (minor/cosmetic, below).

## Root cause
- ATK-001: `PhaseReopen#call` and `Release#release` read the record's status and computed the reset set or ran the checks before taking the record lock, then wrote under it. Two commands could both pass their checks against the same state, so both wrote.
- ATK-002: `Text.free_text!` refused only `\p{Cntrl}`; zero-width, bidi and line-separator characters (category Cf, Zl, Zp) passed into the record, where the content scan later rejects them.
- ATK-003: `ParallelRun.parse_env` echoed the text before the first `=` as a variable name (a whole credential when `NAME=` was forgotten), and the `--env=NAME=VALUE` spelling fell through to the generic "unknown option(s)" message, which prints the argument.

## Changes made
- `ChangeRecord#locked` (reentrant record lock). `PhaseReopen` and `Release#release` now do the status check, reset-set computation, judgment/lifecycle/gate checks and the write inside one lock hold.
- `Text.free_text!` also refuses `[\p{Cf}\p{Zl}\p{Zp}]`.
- `parse_env` echoes a name only when it is a short identifier (`\w{1,64}`), otherwise says the text is not shown; `phase run` refuses `--env=...` with a message that does not echo the value.
- Tests: invisible-character refusal and no-echo of a mistyped name (`test/text_free_text_test.rb`); four concurrent reopens produce one reset and one history entry (`test/phase_reopen_test.rb`).

## Not changed, with reason
- EVAL-F1 (gate on a reopened phase prints SKIP, exits 0), EVAL-F2, EVAL-F3, EVAL-F4: minor or cosmetic; `change close` still refuses, so nothing passes wrongly. Left for a person to decide whether to schedule. EVAL-F1 touches AC-014 wording and should be settled with the specification owner.
- ATK-004: accepted residual (TB-3). ATK-005: documented residuals. ATK-006: needs a run outside the guarded session.
- `docs/` and `.ai/` are outside this skill's write set; no documentation or control-plane text was changed.

## Evidence invalidated
Implementation changed (`lib/soft_foundry/{change_record,phase_reopen,release,text,parallel_run,cli}.rb`, two test files), so verification, evaluation, attack, review and judgment evidence bound to earlier commits is stale.

## Required reruns
Verify, then evaluate, attack (ATK-001 race, ATK-002 characters, ATK-003 echo cases should be re-driven), review, judge.
