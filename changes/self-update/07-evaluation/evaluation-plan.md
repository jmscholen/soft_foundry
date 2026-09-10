# Evaluation Plan

## Intent being proven
A maintainer can ask whether a newer Soft Foundry release exists and gets an honest answer, without anything being installed unless they explicitly ask for it.

## Personas
A repository maintainer or engineering agent who has Soft Foundry installed and wants to know whether to update.

## Journeys
| ID | Steps | Assertions | Result |
| --- | --- | --- | --- |
| EVAL-001 | `soft-foundry update` | reports current version, an honest answer about latest, writes nothing | pass |
| EVAL-002 | `soft-foundry update --yes` when nothing is available to install | same honest report, installer never invoked | pass |
| EVAL-003 | (unit-level, injected) an update is available without `--yes` | reports it, tells the operator to rerun with `--yes`, installer never invoked | pass |
| EVAL-004 | (unit-level, injected) an update is available with `--yes` | installer invoked with the correct version, success reported | pass |

## UI walkthrough evidence
No UI; the CLI's own text output is the interface. `evidence/journey-transcript.log` is the real transcript from live invocations against the actual installed gem and the real RubyGems API, not a fixture or a mock.

## Accessibility interaction
Not applicable: non-interactive CLI, plain-text output, no keyboard-navigation surface.
