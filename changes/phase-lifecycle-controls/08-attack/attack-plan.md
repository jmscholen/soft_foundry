# Attack Plan

Commit: 1ce44defbcdf87589b6feb6c8b69a8f6ad3733cd. Size from `soft-foundry change size phase-lifecycle-controls --phase attack`: `full_route_sweep` (no scope is declared, so the whole repository is sized largest). The only network-facing routes are the read-only UI routes, and every one was swept (ATTACK-016); the lifecycle commands were attacked in full.

Re-run after remediation (529e749): all drivers were re-run against a fresh clone at this commit, with drive12 added for 22 invisible and look-alike character classes. Size re-confirmed: `full_route_sweep`.

## Authorization envelope
- Target: the soft-foundry CLI, guard hook and loopback UI at the commit above, run from a throwaway clone and throwaway fixture repositories in the system temp directory. Environment: local.
- Authorized by: the person who started this run with `soft-foundry phase run attack`; the target is the tool's own code, which that person owns.
- Allowed surfaces: the CLI (phase reopen, phase run with a stub `claude` shell, change release/discharge/close/status/list, check, ci, scan, gate, guard), the guard hook fed synthetic payloads, `UI::Server#respond` called in-process, and hand-edited records inside the fixtures.
- Prohibited surfaces: the real repository's record, working tree, index and history; any live coding-shell session or provider API (no phase was run against a real model); any network access; the real home directory state.
- Data constraints: synthetic fixtures and fake credentials only.
- Network constraints: none used; the UI server was never bound to a port.
- Destructive actions: prohibited; none taken outside throwaway directories.

## Intent to challenge
Intent (specification REQ-003..025, threat model MIT-001..009): a phase session cannot rewrite lifecycle state; reopen and release only move state and never create evidence; free text is safe to print and store; `--env` values never leave the child's environment; record writes are serialised so no sequence of commands yields an impossible record; only isolated phases run in parallel; and `ci` refuses a record that claims `released` without a sound release block.

## Threats mapped
THREAT-001/002 marker and its bypass (ATTACK-001, 002, 003); THREAT-003 guard marker values (003); THREAT-004 forged and malformed release (004, 005, 006); THREAT-005 auto-reopen and reopen misuse (014, 015); THREAT-006 injection and XSS (007, 008, 016); THREAT-007 env secrets (009); THREAT-008 locking and races (010, 011); THREAT-009 parallel scope and HEAD (012, 013). THREAT-010 (shared adopter resources) is accepted residual risk and was not attacked.

## Adversarial journeys
Each journey is a case in `cases.yml` with threat ID, attempted violation, starting privilege, steps, expected safe behavior, observed result and evidence. Journeys: marker refusal and bypass; malformed markers under the guard; forged finished record then release; release/discharge/close sequence and hand-edited release blocks; hostile text through every free-text flag; stored XSS through the UI API; credential leaks through the record, process title and messages; concurrent release/reopen and concurrent reopens; lock and symlink planting (blocked); parallel refusals and a committing session; stale auto-reopen; reopen from refused states; UI verbs, host, site and token.

## Method notes
Drivers (in `evidence/scripts/`) build fixture repositories with the repository's own test fixtures, run `soft-foundry` as a subprocess with the session marker unset (this session itself runs under the marker, which the first attempt proved by being refused), and log commands, exit codes and output. The sessions run by `phase run` were a stub shell, so what is attacked is the runner, guard and record logic, not a model.

## Safety boundary
Nothing outside the envelope was touched. The runtime guard refused one shell command that named the `.soft-foundry` directory (ATTACK-011); that was treated as part of the scope and not worked around.
