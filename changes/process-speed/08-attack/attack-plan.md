# Attack Plan

## Intent to challenge
process-speed makes the lifecycle converge, and only a person's recorded decision may get a change past its human checkpoints. The attack tries to break that: get past the remediation cap or the must-list approval with no decision, leave the awaiting_human park, change code under a documentation-only reopen, withdraw an approved must, mark an in-change finding as outside the change, make a new record look legacy, and get small check sizes for a diff that is not documentation. The cases follow the must criteria (AC-002, AC-004, AC-007, AC-010, AC-015) and the code the change modified: `process_rules.rb`, `gate.rb`, `phase_reopen.rb`, `phase_seal.rb`, `sizing.rb`, `advisory.rb`, `git.rb`, `release.rb`.

Size: `soft-foundry change size --phase attack` reports `full_route_sweep` because no scope is declared (evidence/change-size.txt). Soft Foundry has no routes or sign-in. For this repository a full sweep means every entry point the change added or changed: `phase reopen` (manual and `--docs-only`), `phase seal` for specify, remediate and intake, the gate checks for intake, specify, verify, attack, review and judge, sizing, and the advisory output. Every one is attacked below.

## Threats mapped
| Threat | Cases |
| --- | --- |
| THREAT-001 fabricated decision | ATTACK-001, 013 |
| THREAT-002 round count reset | ATTACK-002, 002b, 002c, 002d, 003, 005f, 012 |
| THREAT-003 leaving awaiting_human by hand | ATTACK-004, 015 |
| THREAT-004 code under a docs-only reopen | ATTACK-005a, 005b, 005c, 005d, 005e |
| THREAT-005 demoting an approved must | ATTACK-006 |
| THREAT-006 in-change finding marked outside_change | ATTACK-007, 016 |
| THREAT-007 new record made to look legacy | ATTACK-008a, 008b |
| THREAT-008 sizing a mixed diff down, or lowering the risk word | ATTACK-009, 014 |
| Failure behaviour (malformed decision) | ATTACK-010 |
| Injection through new free-text fields | ATTACK-011 |

THREAT-009 (concurrency) and THREAT-010 (resource exhaustion) have `attack_case_required: false` and were not attacked.

## Rerun
This is the second run of the phase. The first ran at 0c213b4 and was reopened only to fix the seal order with evaluate. No code has changed since (`git diff 0c213b4 HEAD` touches only 07-evaluation and metadata.yml). This run executes every earlier probe again at the current HEAD. It also adds five cases the first run did not try: the first THREAT-002 vector (delete reopen history), a forged decision committed by hand, the risk word lowered by a hand commit, a cap decision reused for a later round, and an absolute-path spelling for outside_change.

## Adversarial journeys
Each case runs in `evidence/attack_probe_test.rb`. It builds a throwaway git repository in a temp directory with the shared fixture (`test/lifecycle_fixture.rb`), makes a change record there, takes the attacker's step (a direct metadata write, a hand commit, a path spelling), and calls the same classes the CLI uses (`PhaseReopen`, `PhaseSeal`, `Gate`, `Sizing`, `Advisory`). Each test prints what it observed as a `[ATTACK-NNN]` line and asserts the safe behaviour, so a failing assertion is a violation. `cases.yml` records the threat, starting state, steps, expected safe behaviour, observed result and evidence for every case.

## Safety boundary
Local only. Every write lands in a temp-directory fixture, never in this repository's records or code, and nothing goes over the network. No production, third-party or real data is involved. Destructive actions were limited to the throwaway fixtures. Production, third-party or destructive security testing would need explicit authorization.
