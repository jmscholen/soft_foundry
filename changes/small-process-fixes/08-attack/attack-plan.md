# Attack Plan

Commit SHA: 821f1e8ffc2ad8de1fe70af87eabe048e1ea222f

## Intent to challenge
Five small fixes must be safe to run on any adopter's machine: `change new --type/--risk` takes only fixed vocabularies and cannot be used to lower the risk controls; the phase runner marks a self-contradicting handoff blocked and touches only the phase it ran; recorded text echoed by `change summary` and `blocked:` cannot rewrite the terminal or forge facts; the summary and runner cannot be hung or flooded; the `protection stated` gate check cannot be passed by omission or a malformed profile glob.

## Size
`soft-foundry change size --phase attack` reports `full_route_sweep` (no scope declared in metadata.yml, whole repository). The change adds no routes, HTTP surface or UI: its doors are the CLI commands `change new`, `change summary`, `phase run` (blocked marking), `gate verify` (protection check) and the guidance text. All five doors were attacked; there is no sign-in or web route to smoke-test.

## Threats mapped
| Threat | Cases |
| --- | --- |
| THREAT-001 path | ATTACK-001, ATTACK-008 |
| THREAT-002 terminal injection | ATTACK-002 |
| THREAT-003 other-phase write | ATTACK-003 |
| THREAT-004 concurrency | ATTACK-004 |
| THREAT-005 hiding blockers | ATTACK-005 |
| THREAT-006 protection claim | ATTACK-006 |
| THREAT-007 hostile glob | ATTACK-007 |
| THREAT-008 risk/track evasion | ATTACK-010 |
| THREAT-009 hidden characters | ATTACK-009 |
| THREAT-010 resource exhaustion | ATTACK-011 |

## Adversarial journeys
Each case in cases.yml records threat, violation attempted, starting state, steps, expected safe behavior, observed result and evidence. All ran in a scratch `git clone` of the repository at the commit above, under `/tmp`, driven by `ruby -I<clone>/lib <clone>/exe/soft-foundry` (the installed `soft-foundry` predates `change summary`) and by small Ruby scripts that call the runner and gate classes directly. Nothing was run against the real worktree except read-only `check` and `change summary`.

## Safety boundary
Local, synthetic data only. No network, no provider calls, no production or third-party target, no destructive action outside the scratch clone. Provider API keys were unset. No model refusal occurred.
