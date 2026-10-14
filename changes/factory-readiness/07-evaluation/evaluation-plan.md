# Evaluation Plan

## Intent being proven
The maintainer of an application repository can install Soft Foundry, open a change, and rely on the guard, the gate, the waiver rule and the executable harness evals, and the live eval of a fresh-context review works on the installed claude shell. There is no graphical UI; the user-facing surface is command-line output, so journeys are run by hand against the real CLI from this source tree (ruby -I lib exe/soft-foundry), outside the unit-test harness.

## Personas
- Maintainer of a Rails-shaped application repository (init, check, change new, eval, change close).
- Implementing agent under the implementation skill (guard decisions).
- Maintainer on a machine with the C locale.

## Journeys
EVAL-001 Rails repository lifecycle (AC-FR-019, AC-FR-020). EVAL-002 guard decisions in block and warn mode, including the REM-002 bypass attempts (AC-FR-007, AC-FR-008, AC-FR-019). EVAL-003 harness eval failure modes (AC-FR-009, 010, 011, 014, 020). EVAL-004 live eval on claude (AC-FR-015). EVAL-005 waivers and change close (AC-FR-016, 017, 018). EVAL-006 C locale (AC-FR-001, AC-FR-005). EVAL-007 documentation against behaviour (AC-FR-021). EVAL-008 fresh-context advisory, negative side (AC-FR-006). EVAL-009 criteria that need planted defects (AC-FR-002, 003, 004, 012, 013), blocked here and left to verification.
Starting state, steps, assertions, evidence and result for each are in journeys.yml. Scratch repositories were built under the session scratchpad, not in this repository, so no application or record outside 07-evaluation was changed.

## UI walkthrough evidence
No graphical UI exists or changed. Evidence is the verbatim terminal transcripts under evidence/, hashed in evidence/manifest.yml.

## Accessibility interaction
surfaces.accessibility is true because the output of command-line commands is perceived by a person. Exercised: every new line in the transcripts (eval, gate, check, change close, guard, doctor) carries a status glyph and then its outcome word (pass, fail, skip, error, warn) at the start of the line, so it reads without color; eval --json carries the same outcomes as data; no command prompted (all ran with stdin closed or piped); failures say what to do next (change close names 14-judgment, the judge command and --force; eval without --shell names the flag; a malformed case names the file). Keyboard-only operation is inherent because there is no pointing device surface; focus order and screen-reader names do not apply to plain text output. Not exercised with a screen reader.

## Re-run note
This plan was re-executed at 9307b23 after REM-003 changed the guard again (cd back to the root, brace expansion, fail-closed on undecidable calls, Grep and Glob guarded), because evidence bound to 98b336f no longer describes the code. The guard also refused two of this session's own tool calls during the run (a Bash command carrying an unresolvable tilde-user token, and a Write outside the repository), live instances of the REM-003 and permission behaviour.
