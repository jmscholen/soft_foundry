# Attack Plan

## Intent to challenge
Scoped verification promises that evidence goes stale for the right changes and only those: a record's declared scope, the repository's shared core and any unclaimed code path stale it; a declaration edit stales it; a full-suite run is reusable only for an identical tree; check size is computed from the diff and never smaller than the diff calls for. The high-risk failure the specification names is stale evidence silently passing the gate. This phase tries to make that happen, to make a recorded run or size say more than was done, and to break the structural checks with hostile input.

## Size and scope of the attack
`change size --phase attack` printed `size: full_route_sweep` (reason: no scope declared, so the whole repository is sized at the largest size). This change has no web routes of its own; the "routes" are the CLI doors and the one browser door the change touches: `gate`, `check`, `change size`, `change status`, `phase run` refusal, and the `/api/change` route of `soft-foundry ui`. All of them were exercised, plus the smoke path (`check`, `gate verify`, `ui` start and token refusal).

## Authorization envelope
Local, ephemeral, synthetic. Every attack ran against throwaway git repositories created under the system temp directory with a copy of this checkout's `.ai/` and `lib/` unchanged; the real repository, its history, its records and any remote were not modified by the attacks. The `ui` server bound to 127.0.0.1 on an ephemeral port in a throwaway repository and was stopped. No network egress, no credentials, no destructive action on anything outside the temp directories. Authorized by the maintainer's own invocation of `soft-foundry phase run attack` on their machine.

## Threats mapped
| Threat | Attack cases |
| --- | --- |
| THREAT-001 declaration narrowing after evidence | ATTACK-001, ATTACK-014, ATTACK-017, ATTACK-019 |
| THREAT-002 blind or empty declarations | ATTACK-002 |
| THREAT-003 cross-record scope abuse | ATTACK-003, ATTACK-013, ATTACK-015 |
| THREAT-004 forged or abusive full-suite records | ATTACK-004, ATTACK-016 |
| THREAT-005 reuse over untracked, ignored, dirty files | ATTACK-005 |
| THREAT-006 undersized checks | ATTACK-006, ATTACK-013 |
| THREAT-007 git failure read as no change | ATTACK-007, ATTACK-014, ATTACK-018 |
| THREAT-008 replay after history rewrite | ATTACK-004 |
| THREAT-009 injection through globs, slugs, YAML | ATTACK-002, ATTACK-004, ATTACK-008, ATTACK-016 |
| THREAT-010 resource exhaustion (attack not required) | ATTACK-009 |
| THREAT-011 structural pass read as proof | ATTACK-010 |
| THREAT-012 markup in scope text, browser view | ATTACK-011 |

## Adversarial journeys
Each case in `cases.yml` records the threat, the attempted violation, the starting privilege, the steps, the expected denial, what was observed and the evidence. Drivers: `evidence/attack3.rb` (ATTACK-017 to 019, probes of the git.branch remediation, transcript `evidence/transcript3.txt`), `evidence/attack.rb` (ATTACK-001 to 010 and the first-pass browser attempt), `evidence/attack2.rb` with `evidence/attack_lib.rb` (confirmation of suspects, ATTACK-011 to 016 and the browser view). Transcripts: `evidence/transcript.txt`, `evidence/transcript2.txt`. The attacker's starting privilege is that of an implementing session: it may edit and commit anything under `changes/<slug>/` for its own record (metadata, tests.yml, handoffs), may commit code, and may not edit `.ai/` through the guard (but a careless or malicious human edit to `.ai/` is modelled in ATTACK-001 because the specification makes that edit a stale cause).

## Intent-violation cases
The intents under attack: stale evidence never passes (ATTACK-001, 013, 014, 015); a claimed full-suite pass names the tree it ran on (ATTACK-004, 005); size is not smaller than the diff demands (ATTACK-006, 013); failures read as failures (ATTACK-007); declarations cannot be blind (ATTACK-002).

## Unauthorized journeys and abuse cases
Unauthorized: editing declarations to avoid staleness (ATTACK-001), repointing the record to a branch that lacks the change (ATTACK-014), citing a record that is not this tree's run (ATTACK-004), moving code out of the path that would stale a record (ATTACK-013). Abuse: hostile strings in globs, slugs, `--since`, `--phase`, branch names and commit_sha (ATTACK-002, 007, 008); YAML aliases and tags (ATTACK-004, 008); symlink out of `changes/` (ATTACK-004); 3000 changed files, 300 sibling records and pathological globs (ATTACK-009).

## Safety boundary
Production/third-party destructive or security testing requires explicit authorization; none was requested or performed. No provider refusal occurred.
