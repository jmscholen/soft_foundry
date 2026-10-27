# Threat Model

Scope: five local CLI and guidance fixes (`change new --type/--risk`, runner blocked-marking, invisible-character guidance, `change summary`, access-control parity rule and gate check). No network, credential, privilege or service is added (REQ-015). The surface is local files and command-line arguments read and written by `soft-foundry`.

## Trust boundaries
See `trust-boundaries.md`. Four matter: CLI arguments to the process; the phase-run agent's handoff file to the runner; recorded change files to the summary and gate; `access_control` globs in the repository profile to the parity check. No new boundary crosses the machine.

## Externally controlled inputs
- `--type`, `--risk`, `--track` and the slug on `change new` (F1).
- The slug argument of `change summary` (F4), which selects a directory.
- The handoff `status`, `blocking`, `notes` and `findings` text written by an agent session (F2, F4). An agent, or content it was fed, controls these.
- `metadata.yml`, handoffs, findings and advisories rendered by the summary: free text from agents and people (F4).
- `tests.yml` `protection` and `protection_note` written by the verification agent (F5).
- `access_control` globs in `.ai/repository.yml`, written by discovery, and the changed-file list from Git (F5).
- Payload text quoted in evidence, which may contain invisible, bidirectional or control characters (F3).

## Authorization boundaries
There is no user authentication. The boundary that exists is the skill write set: a phase-run agent writes only inside its phase directory, and only the runner may change that handoff's status afterwards. The runner's blocked write must touch only the handoff of the phase just run (REQ-005, REQ-015). The verification agent controls whether protection is declared; the gate checks that it is stated, not that it is true (limit recorded in the rule text).

## Abuse cases
See `threats.yml` (THREAT-001 to THREAT-010). In short: a slug that escapes `changes/`; terminal-escape or bidirectional text in free text echoed by the summary or the `blocked:` line; the runner writing outside the handoff or racing a parallel finish; a `blocked` rewrite hiding or discarding blocking items; an agent routing around the blocked-marking by editing the status itself; verification claiming `in_force` it did not run, or `not_applicable` on every check to dodge the parity gate; vocabulary drift that lets `risk` be mis-set to evade the risk-based waiver rules; guidance that teaches raw hidden characters instead of escapes.

## Injection / XSS / CSRF / SSRF / file risks
- Path traversal: the `change summary` slug and `change new` slug become paths. Must be validated as a known change name, not joined blindly.
- Output injection: summary and `blocked:` echo agent-written text to a terminal. ANSI escape or bidirectional characters could rewrite what a person sees. Strip or escape control characters from echoed free text.
- YAML: handoff and metadata are parsed with the existing safe loader; the runner's rewrite must preserve structure and not interpolate text into YAML by string concatenation.
- Glob handling: `access_control` globs are matched against paths only; no shell expansion or command execution.
- XSS, CSRF, SSRF: N/A. No web surface, no HTTP request, no browser is touched (the read-only `ui` view reads the same files but is not changed here; a note in the `blocked` text is plain text it already escapes).

## Resource exhaustion and DoS
The summary reads one metadata file and at most sixteen handoffs (REQ-017). An oversized or deeply nested handoff could slow the parse; bound the read size and report `unreadable`. The runner's extra read-modify-write is constant per run. Glob matching over the changed-file list is linear. A very long `blocking` list or note is truncated when echoed.

## Infrastructure exposure
None. No deployment, IaC, CI workflow, port or credential change.

## Proposed attack cases
- ATK-001 `change summary ../..` and `change summary /etc` and a slug with a NUL or separator: refused, nothing read outside `changes/`.
- ATK-002 Handoff `notes`/`blocking` containing an ANSI escape sequence and a bidirectional override, built in a script: the summary and `blocked:` output contain no raw escape.
- ATK-003 Runner finishes a session whose handoff is `complete` with blocking items, in a `--parallel` run with a second phase finishing at once: both handoffs correct, no other phase file changed.
- ATK-004 Handoff with a `blocking` list and a hostile `notes` value (multi-line, YAML-looking): rewrite leaves valid YAML, blocking entries byte-identical.
- ATK-005 Hand-edited `complete` handoff with blocking items still fails the gate.
- ATK-006 Profile with `access_control`, changed path matching, every check `not_applicable` and no note: gate fails `protection stated`; one `disabled` check with an empty note fails.
- ATK-007 Profile `access_control` glob that is unreadable or malformed: the check fails and does not silently pass.
- ATK-008 `--risk` and `--type` given values like `High`, `low; rm`, empty, repeated flags; `--risk high --track iterative`: refused, no directory created.
- ATK-009 Oversized or malformed handoff for the summary: shown `unreadable`, exit zero, completes quickly.
- ATK-010 Guidance text contains no raw invisible character itself, and `check` content scan stays clean.
