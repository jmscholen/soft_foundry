# Threat Model

## Trust boundaries
See `trust-boundaries.md`. In short: the network outside the machine, other web origins in the viewer's browser, other local processes, and the change records themselves are each outside the trust of the server process and the page.

## Externally controlled inputs
- The HTTP request: method, target, headers. No body is read.
- `.ai/workflow.yml`, the skills, and every file under `changes/`, which a contributor, a dependency of the workflow, or a cloned repository's author may have written.
- Nothing else. The server takes no configuration beyond `--port`.

## Authorization boundaries
There is no authentication. Authorization is by reachability: only a client on this machine can connect, and a browser page from another origin is refused the data. Any local process, and any local user on a shared machine, can read what the page shows. The maintainer accepted this for a read-only view of files that are already on the same disk.

## Abuse cases
- A website the viewer has open tries to read the board through the viewer's browser (cross-origin fetch, DNS rebinding).
- A website makes the viewer's browser send a state-changing request to the server.
- A record's text carries markup or script meant to run in the page.
- A request names a file outside the page's own three files.
- A local process holds connections open or sends oversized requests to make the page unusable.
- A record points outside the repository (a symlink) to make the server disclose another file.
- Someone starts the server expecting it to be reachable from another machine.

## Injection / XSS / CSRF / SSRF / file risks
- XSS: THREAT-004. Record text is rendered; mitigated by text-only DOM construction and a CSP with no inline or remote script.
- CSRF: THREAT-005. There is no state to change: only GET and HEAD are answered and no handler writes.
- SSRF: N/A. The server makes no outbound request.
- File: THREAT-003, THREAT-009. No path comes from the request; a slug must be one the repository lists.
- Injection: the gate runs `git` with arguments built from records, as it does for the CLI today; the server adds no new argument source, since the only request value used is a slug already validated against the listing.

## Resource exhaustion and DoS
THREAT-006. Bounded header size, a read deadline, one request per connection, a connection limit that evicts the longest-idle connection, a 2 s reuse of API answers, and one computation at a time. A local client can still make the server run one gate evaluation (about 0.4 s) per distinct change every 2 s.

## Infrastructure exposure
THREAT-007. The listener binds 127.0.0.1 only and there is no flag to change it.

## Proposed attack cases
ATTACK-001 traversal and out-of-table paths; ATTACK-002 rebinding Host headers; ATTACK-003 cross-site data read; ATTACK-004 writes; ATTACK-005 held connections; ATTACK-006 oversized, malformed, and smuggled requests; ATTACK-007 hostile record text, over the wire and rendered; ATTACK-008 a symlinked metadata file; ATTACK-009 reaching the listener from off the machine.
