# Evaluation Plan

## Intent being proven
A maintainer can adopt Soft Foundry, create a change, record real spend against it as work happens, and see whether that spend is within the declared budget for the change's risk level, using OpenRouter as one of the priced providers.

## Personas
A repository maintainer adopting Soft Foundry for the first time, tracking cost across a change as it progresses through phases.

## Journeys
| ID | Steps | Assertions | Result |
| --- | --- | --- | --- |
| EVAL-001 | `init` a fresh repo, `change new`, `budget status` with no entries | ledger scaffolded, status reports "unknown" spend rather than $0.00 (honest about lack of data), a cap is shown | pass |
| EVAL-002 | `budget record` two entries (OpenRouter, then Anthropic), `budget status` | totals sum correctly across providers/entries, both token counts and dollar amounts accurate | pass |
| EVAL-003 | run `soft-foundry version` under a Ruby 2.7.8 interpreter | plain "requires Ruby >= 3.2" message, exit 1, no raw multi-page `SyntaxError` | pass |
| EVAL-004 | `soft-foundry doctor` after init | `.ai/manifest.yml` check line present and passing, confirming the new budget policy and template files installed correctly alongside everything else | pass |

The over-cap (exit 2) outcome is proven by the automated test suite (`CLIInitTest#test_status_reports_over_cap_with_exit_2`) rather than a fifth manual journey; see `06-verification/results.md`'s scope note.

## UI walkthrough evidence
No UI; the CLI's own text output is the interface. `evidence/journey-transcript.log` is the captured transcript of the real commands and their real output, run against a fresh scratch git repository, not a fixture or a mock.

## Accessibility interaction
Not applicable: `budget status`/`budget record` are non-interactive CLI commands with no keyboard-navigation surface. Output is plain text, one line per fact, readable by screen reader or `grep` without color or symbols.
