# Evaluation Plan

Commit: 6357775efd74e706a2955f0f73b00ad0d897f573 (code is unchanged since the verified commit 529e749, the remediation of ATK-001/002/003; later commits touch only change records). The earlier evaluation of this change was bound to 0af7da5, before that remediation; every journey was rerun at this commit and the new journey EVAL-010 drives the remediated behavior.
Check size: `full_route_sweep` (`soft-foundry change size phase-lifecycle-controls --phase evaluate`: no scope declared, so the whole repository is sized at the largest size). The routes of this change are every new command and every consumer of the new states, so every one was driven.

## Intent being proven
A person running a gated change can (1) reopen a phase and its downstream with a recorded reason, or have a stale phase reopened automatically by `phase run`; (2) run the isolated phases evaluate and attack side by side with per-session environment and no lost record updates; (3) release a judged change with named open items, discharge them, and close it; and (4) see all of that, as words and not color, in every command's output and the UI.

## Personas
- **Maintainer**: owns a gated change; reopens phases, runs phases, releases and closes.
- **Phase session**: a fresh coding-shell session carrying `SOFT_FOUNDRY_PHASE`; must not be able to reopen, release, or discharge, and is held to its own skill by the guard.
- **Screen-reader or terminal-only reader**: reads piped, NO_COLOR output and the UI's page source.

## Method
Every journey drives the real `exe/soft-foundry` of this checkout (HEAD above) as a subprocess against throwaway git repositories built in /tmp by `evidence/mkrepo.rb` (the shipped `.ai/` plus `soft-foundry change new`, phases completed at HEAD). Coding shells are replaced by a stub `claude` on PATH that sleeps, records its environment, and completes only its own phase directory. Provider keys were unset. The scripts are `evidence/j*.sh`; their captured output is `evidence/j*.txt`. No application code, test, or expected outcome was modified.

## Journeys
EVAL-001 reopen, refusals, markers. EVAL-002 gate and close after reopen, remediate transition, waived phases, judge reopen, blocked statuses. EVAL-003 parallel run (concurrency, `--env`, secrets, refusals, one-fails, 20 repeats, signals, HEAD movement). EVAL-004 release, discharge, close, ci, check lint. EVAL-005 released record among consumers (status, list, ci, gate, learn, ps, UI API and page source). EVAL-006 auto-reopen of stale evidence and the timeline. EVAL-007 guard session markers. EVAL-008 output accessibility. EVAL-009 `check`, harness evals, and usage/control-plane text. EVAL-010 the remediation: record lock under concurrent reopen and release, invisible and direction-changing characters in free text, and `--env` forms that could echo a credential. Each lists requirement-bound criteria in `journeys.yml`.

## UI walkthrough evidence
The UI is a read-only loopback page. It was served (`soft-foundry ui`), its token gate was exercised (401 without the token), and `/api/changes` returned the released record with `released: true` and `open_items: 2`. The page was NOT rendered in a browser in this session (no browser tool was used); the rendering was assessed from `app.js` source only. This is a stated limit, not a pass for visual behavior.

## Accessibility interaction
`surfaces.accessibility` is true. Exercised: all captured command output (success and refusal paths of reopen, release, discharge, parallel) piped with NO_COLOR set and stdin closed: 0 lines containing a non-ASCII byte or an escape sequence, no prompts, outcomes as words with stable prefixes, every refusal names what went wrong and the next action. UI source: the release items are a `table` with `caption`, `th scope="col"` header cells and `th scope="row"` ids, the state is the word "open" or "discharged", the released state is the word "Released" with the open-item count, and scrolling regions carry `tabindex="0"`, `role="group"` and a label. Keyboard-only operation, visible focus, and screen-reader announcement in a rendered page were not exercised (no browser); that remains owed.
