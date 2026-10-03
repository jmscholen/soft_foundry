# Threat Model

A delta on `changes/ui-server/03-threat-model/` and `changes/ui-processes/03-threat-model/`. This change lets a request choose which repository is read, makes the set of readable repositories depend on what is running, and adds a token.

## Trust boundaries
See `trust-boundaries.md`.

## Externally controlled inputs
- The `repo` parameter of a request, and the token header.
- Which directories have a coding shell or a soft-foundry command running in them: any process of this user can make a directory that has `.ai/workflow.yml` into a repository the server reads.
- The records and workflow of every such repository.
- `--repo` paths, from the person starting the server.

## Authorization boundaries
New: a bearer token. Whoever has the link can read everything the server knows; nothing else can. The link is printed to the terminal, so it is as private as the terminal and its scrollback. Any process of the same user could read the server's memory or the terminal anyway; the token is aimed at other local users, other origins in the browser, and anything that can reach the port but not the terminal.

## Abuse cases
- A request names a directory to make the server read it.
- A request asks for a change of one repository through another's id.
- Something reads the data without the token: no header, a guessed one, the token in the address, a cookie.
- A website gets the token: from the Referer, from history, from a cross-origin read.
- A local process makes the server read a hostile repository by opening a shell-named process in it.
- The list of repositories grows without bound.

## Injection / XSS / CSRF / SSRF / file risks
- File: THREAT-001. Only issued ids select a repository; only that repository's own listing selects a change.
- XSS: a repository's directory name and the records of repositories the user did not choose are rendered; text-only rendering and the CSP are unchanged (THREAT-004).
- CSRF and cross-origin reads: a custom header cannot be sent cross-origin without a preflight, which the server refuses; the earlier Host and cross-site checks remain (THREAT-002, THREAT-003).
- SSRF: N/A, no outbound request.

## Resource exhaustion and DoS
Each known repository costs one overview (reading each record's metadata) per uncached home page, and a gate run per open record when its board is opened. The registry grows by one entry per distinct governed directory seen and is never trimmed while the server runs (THREAT-005).

## Infrastructure exposure
Unchanged: loopback only.

## Proposed attack cases
ATTACK-001 data without the token, guesses, and the token in the wrong place; ATTACK-002 the token from another site or name; ATTACK-003 repositories named by path or by an id not issued, and a change asked of the wrong repository; ATTACK-004 a repository whose name is markup; ATTACK-005 paths in answers.
