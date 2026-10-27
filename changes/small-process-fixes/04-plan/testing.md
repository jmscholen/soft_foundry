# Test Plan

testing_strategy: write each test before its code and record the failing run (RED) then the passing run (GREEN). Minitest with `with_fixture_repo`. Run the suite with provider keys unset, as the local environment masks CI.

## Unit
- Escaper: ESC, CR, NUL, bidi override, zero-width characters become visible `<U+XXXX>`; long lists truncate with a count; plain text unchanged.
- Vocabulary constant: exact match only; `Fix`, ` fix`, `fix ` and empty are refused.
- Blocked marking on a handoff hash: complete plus blocking becomes blocked, `blocking` identical byte for byte, notes appended; complete plus empty blocking unchanged; only `status` and `notes` differ.
- `protection stated` evaluation: each combination of profile glob present or absent, match or none, `in_force`, `disabled` with and without note, `not_applicable` only, older records without the fields.
- Summary reader: bounded read, alias limit, malformed YAML yields `unreadable` with a reason.

## Integration
- `change new` end to end in a fixture repo: types and risks recorded; omitted values keep placeholders; bad values leave no directory; `../x`, absolute and NUL slugs refused; `--risk high --track iterative` refused.
- Runner: single run, `--parallel` run and auto-reopened run each with a fake session leaving complete plus blocking; every other phase's handoff is byte-identical afterwards; `blocked:` line printed; simulated lock failure prints `warn:` and leaves the handoff as written with nonzero exit.
- Gate: a hand-edited complete handoff with blocking items still fails.
- `change summary` on a fixture with several complete phases, one with findings, one blocked, one open human decision; no file modified (compare tree hashes); gate not invoked; unknown slug refused with known names; a handoff containing ANSI and CR in notes is escaped in output; output with `NO_COLOR` set and non-TTY has no escape sequences.
- `check`: passes on the shipped tree; fails when the constant, template comments or `workflow.yml` risk names disagree; content scan passes over the edited guidance and rule files and still fails a raw zero-width character in evidence.
- Gate with a fixture profile declaring `access_control` and a changed path that matches; the same with no declared key; this repository's own gate result unchanged.

## Acceptance criteria coverage
| Criterion | Test layer | Planned test |
| --- | --- | --- |
| AC-001 | Integration | `change new --type fix --risk low` writes both values |
| AC-002 | Integration | omitted flags keep placeholders, exit zero |
| AC-003 | Integration | bad `--type` and `--risk` refused, no directory, message lists allowed values |
| AC-004 | Integration | `check` lint on drift; `--risk high --track iterative` refused |
| AC-005 | Integration | runner single run: blocked status, kept item, notes, `blocked:` line |
| AC-006 | Integration | runner complete with empty blocking untouched, no line |
| AC-007 | Integration | parallel and auto-reopened runs identical; other handoffs unchanged |
| AC-008 | Integration | gate fails hand-edited record; lock failure gives `warn:` and unchanged handoff |
| AC-009 | Integration | text search of the three skills and README for the guidance; content scan still fails a raw zero-width character |
| AC-010 | Integration | full summary on a mixed fixture; tree unchanged; gate not run |
| AC-011 | Integration | unknown slug refusal; malformed handoff shows `unreadable`, exit zero |
| AC-012 | Integration | `NO_COLOR` and non-TTY capture: no escapes, words, prefixes, errors name the fix |
| AC-013 | Integration | rule file exists and states in-force requirement, `access_control` source and states |
| AC-014 | Unit | `disabled` without note fails naming the check; older `tests.yml` unaffected |
| AC-015 | Integration | gate fails naming the matching path; passes with `in_force` or all stated with notes |
| AC-016 | Integration | no `access_control` or no match: not applicable, result as before |
| AC-017 | Integration | static check that no network or credential code is added; runner write touches only the finished phase's handoff |
| AC-018 | Integration | each signal is a plain-text line in captured output |
| AC-019 | Integration | summary on a normal record completes under one second and records no gate call |
| AC-020 | Review | diff and policies compared; no data, telemetry or network behaviour changes |

Attack cases ATK-001 to ATK-010 from the threat model are executed by the attack phase; this plan adds unit and integration tests for the same inputs (traversal slug, ANSI and bidi text, wrong-phase write, parallel race, falsified `blocking`, protection omissions, bad globs, vocabulary variants, raw hidden characters in guidance, alias bomb).

## Not covered and why
- Harness-eval cases: the directory is denied to this phase and its permissions for implementation are unconfirmed; covered by the tests above, gap recorded as an open item.
- Truth of a `protection: in_force` claim: the gate checks presence only by design; left to review.
- The read-only `ui` page: out of scope.
