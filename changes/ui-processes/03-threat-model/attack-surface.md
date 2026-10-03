# Threat Model

A delta on `changes/ui-server/03-threat-model/`, which covers the listener, the routes, and the page. This change adds one data route, two subprocess calls, and a new kind of untrusted input: other processes' command lines.

## Trust boundaries
See `trust-boundaries.md`.

## Externally controlled inputs
- The output of `ps`: every process of this user, each with a command line that process chose.
- The working directory of each soft-foundry process and of each coding shell.
- For a session in another repository: that repository's checked-out branch name and the `status` and `current_phase` of the matching change record there. Another repository's files are someone else's input.
- The request to `/api/processes` (no parameters are read).

## Authorization boundaries
Unchanged: reachability only. The new data (which commands are running, in which directories, with which pids) is visible to the same local parties, who can run `ps` themselves.

## Abuse cases
- A process names itself soft-foundry and puts markup, a path, or a secret in its arguments, to inject into the page or have it repeat a secret.
- A real runner is given a secret after `--`, or a session's prompt holds one, and the list repeats it.
- A request tries to pass a pid or a command to the listing.
- Listing is used to signal or disturb a process.
- A website reads which sessions the viewer is running.

## Injection / XSS / CSRF / SSRF / file risks
- Command injection: THREAT-002. `ps` and `lsof` are run with fixed argument arrays; the only variable is an integer pid taken from `ps` output by a digits-only pattern.
- XSS and disclosure through command lines: THREAT-001. Only validated fields are reported and the page renders them as text.
- CSRF, SSRF, file: unchanged from ui-server; the route reads no parameter and no file named by a request.

## Resource exhaustion and DoS
One `ps` and one `lsof` per soft-foundry process per uncached answer, reused for 2 s under the server's single computation lock. A machine with very many soft-foundry processes pays one `lsof` each.

## Infrastructure exposure
Unchanged: loopback only.

## Proposed attack cases
ATTACK-001 a spoofed process with hostile arguments; ATTACK-002 the route against the server's refusals and with parameters; ATTACK-003 listing does not disturb processes; ATTACK-004 a prompt mentioning soft-foundry; ATTACK-005 hand-started sessions carrying a token, in and out of Soft Foundry repositories.
