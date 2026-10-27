# Evaluation Plan

Commit SHA: 821f1e8ffc2ad8de1fe70af87eabe048e1ea222f
Size: `soft-foundry change size --phase evaluate` gave full_route_sweep (no scope declared, whole repository). This product has no UI or web routes; its "routes" are CLI commands, so the sweep covers the commands this change touches (`change new`, `change summary`, `check`) run for real in a scratch repository created with `soft-foundry init`.

## Intent being proven
An adopter can record type and risk at creation, gets clear refusals for bad values, and can read a latest-state summary, with plain-text accessible output.

## Personas
Maintainer / adopter engineer running the CLI locally.

## Journeys
See journeys.yml (EVAL-001 to EVAL-006). Behaviors that need a live phase-run session (runner blocked-marking, parallel/auto-reopen, write-failure warn) and the gate's protection check are not driven here; they are covered by the verification suite (AC-005 to AC-008, AC-014 to AC-016) and are listed as not exercised.

## UI walkthrough evidence
No graphical UI. Evidence is captured CLI transcripts in evidence/, checked for escape sequences (none; NO_COLOR=1, stdout piped).

## Accessibility interaction
surfaces.accessibility is true. Exercised: output captured non-TTY with NO_COLOR set; zero ESC bytes in all transcripts; outcomes are words (`unreadable`, `pending`, "is not allowed"); one fact per line with stable prefixes (`phase-status:`, `findings:`, `blocking:`, `owed:`, `note:`); errors name the fix; no prompting. Keyboard/focus/screen-reader behavior is N/A beyond that: there is no interactive element.
