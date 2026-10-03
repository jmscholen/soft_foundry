# Change Intake

## User intent
The maintainer asked for "a user interface to better understand each gate visually and understand what is going on", chose a live local server that is read-only, and approved a plan in three stacked changes. This is the second: the server, the `ui` command, and the first two views (the board of all changes and one change's gates).

## Desired outcome
`soft-foundry ui` prints a loopback URL. The page at it shows every change record phase by phase, and for one change each gate with its checks, and follows the records as they change.

- REQ-UI-001: `soft-foundry ui [--port N]` starts a server on 127.0.0.1 (a free port by default), prints `ui: serving http://127.0.0.1:PORT/ (read-only; press Ctrl-C to stop)`, serves until interrupted, prints `ui: stopped`, and exits 0. A port in use, a bad port, an unknown option, and a missing control plane are each refused with exit 1 and a line saying what to do. It does not prompt and does not open a browser.
- REQ-UI-002: the server answers GET and HEAD on exactly six routes: `/`, `/app.css`, `/app.js`, `/api/workflow`, `/api/changes`, `/api/change?slug=`. Anything else is 404, any other method 405. Nothing in a request names a file; a slug is accepted only if the repository's own listing contains it.
- REQ-UI-003: the server refuses a request whose Host header is not `127.0.0.1:PORT` or `localhost:PORT`, and refuses a data request a browser marks as coming from another site. It sends no CORS headers. Every response carries a Content-Security-Policy allowing only same-origin script, style, and fetch, plus `nosniff`, `no-referrer`, and `no-store`.
- REQ-UI-004: request headers are capped at 8 KB and must arrive within 2 s; no body is read; one request per connection. A connection that sends nothing cannot delay or crowd out others. An API answer is reused for 2 s and only one is computed at a time.
- REQ-UI-005: the board view lists open changes (gated now) and closed records (as recorded) with one cell per phase, flags for failing, stale, merged-not-closed, exploring, advisories, and unreadable records, and a key.
- REQ-UI-006: the change view shows the sixteen gates in order with each gate's state, and for the selected gate its status, times, commit, every check with outcome and detail, blocking conditions, and findings; why a pending phase may stay pending; the track; advisories; and a note explaining stale gates on a closed record. The selected gate is addressable by URL.
- REQ-UI-007: the page polls every 5 s, not while hidden or paused; a poll redraws only when the data differs, keeps keyboard focus where it was, and announces the change once to assistive technology. A failed or refused request is explained on the page.
- REQ-UI-008 (accessibility, WCAG 2.2 AA): every state is a word and a shape, never colour alone (1.4.1); text contrast at least 4.5:1 in both colour schemes (1.4.3); everything operable by keyboard with a visible focus indicator (2.1.1, 2.4.7); language, title per view, headings, landmarks, table headers with scope (3.1.1, 2.4.2, 1.3.1); content reflows at 320 CSS px outside data tables (1.4.10); updating can be paused (2.2.2); standalone targets at least 24 px (2.5.8); motion off under reduced-motion.
- REQ-UI-009: every string from a record reaches the page as a text node or attribute value. The script contains no API that parses a string as markup or code; the page has nothing inline and nothing remote.

## Constraints
- No new runtime dependency: `socket`, `json`, and `uri` are standard library. No build step, no CDN, no web font.
- `.ai/rules/security.md`: change records are attacker-writable input; guard against XSS, CSRF, path traversal; no secrets or local paths in what is served.
- `.ai/rules/accessibility.md`: WCAG 2.2 AA for the page; CLI output rules for the command.
- Page files live under `lib/soft_foundry/ui/assets/`: packaged by the gemspec, and not under `.ai/`, which is copied into adopter repositories.

## Non-goals
- No action from the browser: no gate run, vet, reopen, close, or edit.
- No `--host`, no TLS, no authentication, no per-run URL token (the maintainer accepted loopback, read-only, and readable by any local process).
- The workflow explainer and the timeline and spend views (change `ui-explainer-timeline`).
- No file contents: the page does not show a phase's documents.

## Task classification
feature

## Initial risk
medium. It adds a listening socket and a hand-written HTTP parser to a tool that had neither, and renders attacker-writable text in a browser. Contained by loopback binding, a read-only fixed route table, and text-only rendering; threat-modelled and attacked in this record.
