# Evaluation Results

Commit SHA: 93acd899cc20cb4c25bc7ffe38d374925c2920fa (second run, after remediation REM-001; the first run, at 98b55d1, is superseded)

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | AC-011 | pass | evidence/journey-transcript.log |
| EVAL-002 | AC-002, AC-003, AC-008, AC-009, AC-010 | pass | evidence/journey-transcript.log |
| EVAL-003 | AC-007, AC-008, AC-009 | pass | evidence/journey-transcript.log |
| EVAL-004 | AC-008 | pass | evidence/journey-transcript.log |
| EVAL-005 | AC-013 | pass | evidence/journey-transcript.log, evidence/recorded-sessions-section.jpg |
| EVAL-006 | AC-012 | blocked | evidence/journey-transcript.log |
| EVAL-007 | AC-008, AC-009 | pass | evidence/journey-transcript.log |
| EVAL-008 | AC-012 | pass | evidence/journey-transcript.log |

What each showed:
- **EVAL-001.** Two installs left exactly one Soft Foundry entry in each of the three agent files beside the person's own theme and hook; both skill files written; doctor said installed for claude, codex, grok, then not installed after uninstall, which left only the person's entry.
- **EVAL-002 (live Claude Code 2.1.293).** One row for the session, with change demo, phase specify, branch change/demo, and the transcript path Claude Code reported; a second prompt through `claude -p --resume` updated `latest` and added no row. The printed `resume` command, run from `/` with a question appended, answered with the original marker, so it reached the same conversation.
- **EVAL-003 (live Grok 1.0.30).** With both the Claude settings entry and Grok's own hook file present, one row, agent grok. The printed command with a question appended answered with the marker.
- **EVAL-004.** Claude Code, asked in plain English with the skill, returned Grok's session and its resume command and said it left out its own lookup session. Grok returned Claude Code's session with the right command and also discarded its own lookup row. Grok's shell found the older installed `soft-foundry` (0.17.1, without `sessions`) on its PATH rather than this checkout's shim, so it fell back to the transcript stores as the skill says and then ran this checkout's command; after this release is installed that detour does not arise.
- **EVAL-005.** The change's data from the running UI server carried all four sessions with resume commands, and the page rendered a "Recorded sessions" heading and list (screenshot).
- **EVAL-006.** Blocked: Codex 0.139.0 could not run a turn ("Your access token could not be refreshed"). Codex capture, the Codex hook payload, and the runner's Codex lookup are covered only by tests with documented payloads (CHECK-001).
- **EVAL-007.** See accessibility observations.
- **EVAL-008 (added after REM-001).** `phase run intake --shell grok -- --always-approve` launched `grok -s <id> --always-approve -p <prompt>`, Grok ran (it then marked the empty demo intake blocked, correctly, for want of a stated intent), `executed_by` held the chosen session ID and the folder, the ledger had exactly that session, and `resume demo intake` printed its command.

## Failures
None at this commit. EVAL-006 is blocked by the local Codex login, not by the change.

Observations for review:
- EVAL-OBS-001 (fixed in REM-001): the resume command now sits on its own line after a "Resume:" label (screenshot).
- EVAL-OBS-002: Grok's prompt hook payload carries no transcript path, so a Grok session's status checks only that its folder exists.
- EVAL-OBS-003: in the browser the list item's accessible name reads ", last prompt , resumable." because its parts are separate nodes; the full text is read in order, but the computed name is fragmentary.

## Accessibility observations
- CLI: with `NO_COLOR` set and every non-ASCII byte deleted, `sessions` output keeps its meaning (`session: … grok resumable`, `where:`, `first:`, `resume:` lines); zero escape sequences; no prompts anywhere. `resume` with nothing recorded exits 1 and says what to run next. Install and uninstall lines start with `installed`, `skip`, or `removed`; doctor's line starts with `pass` or `warn`.
- UI (EVAL-005, read through the browser's accessibility tree): a region labelled "Recorded sessions" with an h2, a description, and a list; each item has the agent as text, the phase as a link (keyboard reachable), the time as a `time` element, the status word in text, and the command as selectable code text. No control is pointer-only. Colour is not the only carrier: the agent name and status are words. Not checked here: 320 px reflow and 200% zoom of the new section, and a screen reader pass (EVAL-OBS-003).

## Scope note
Performed by the interactive session against a throwaway repository with this repository's real control plane, the real CLI executable through a `PATH` shim, live Claude Code and Grok sessions, and a temporary HOME for installs. `ANTHROPIC_API_KEY` was unset for the Claude Code calls because the key exported on this machine is rejected; Claude Code then used its own login. Spend: four Claude Code turns, four Grok turns, and one Grok intake phase run, under a dollar.
