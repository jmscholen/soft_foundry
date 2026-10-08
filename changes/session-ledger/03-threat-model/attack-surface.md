# Threat Model

## Trust boundaries
See `trust-boundaries.md`.

## Externally controlled inputs
Hook payload fields (`session_id`, `cwd`, `prompt`, `transcript_path`, `hookEventName`); the branch name and `changes/<slug>/metadata.yml` of whatever repository the payload's folder is in; the ledger file's existing contents; the person's existing agent settings files.

## Authorization boundaries
Single user. The guard's skill permissions are the only authorization in play (REQ-SL-001).

## Abuse cases
- A prompt or folder name crafted so a printed resume command runs something else when pasted.
- A prompt containing a key, kept in plain text on disk.
- Terminal escape sequences in a prompt or branch name that rewrite what `sessions` shows, or that act on the terminal.
- A huge or malformed payload that stalls every prompt.
- Another local user reading or planting a ledger.
- A Grok session writing outside the active skill through a tool name the guard does not know.

## Injection / XSS / CSRF / SSRF / file risks
Shell injection via printed commands (THREAT-001); terminal escape injection (THREAT-003); HTML injection in the UI (THREAT-007); symlink redirection of the ledger or settings files (THREAT-004, -006). No network requests, so no SSRF or CSRF beyond the UI's existing token.

## Resource exhaustion and DoS
An oversized stdin payload or an enormous ledger slowing every prompt (THREAT-005).

## Infrastructure exposure
N/A: no deployed service.

## Proposed attack cases
ATTACK-001 shell metacharacters in folder and session ID; ATTACK-002 ANSI and control characters in prompt and branch; ATTACK-003 secret shapes in a prompt; ATTACK-004 symlinked ledger and settings targets; ATTACK-005 an 8 MB payload and a malformed ledger line; ATTACK-006 Grok write/search_replace/read_file/run_terminal_command against a denied path; ATTACK-007 HTML in a prompt shown in the UI.
