# Evaluation Plan

Commit evaluated: 119e431770bbdddc4048eb625672ee358405fe77 (code tree identical to the verified commit 4988779; the commit between them records verification only).

## Intent being proven
A maintainer can put a change on the light track and take it from creation to a closed record through specification, implementation, verification, one review and judgment, without the tool asking for the phases the track makes optional, and without losing any lock. The two carried defects (outside-change paths, the remediation round count) are fixed as a user of the gate sees them, a text-only change is sized smaller at verification, and gated, iterative and older records behave as before.

## Size
`soft-foundry change size --phase evaluate` (worktree code) reports `full_route_sweep`: no scope is declared, so the whole repository is sized at the largest size. Soft Foundry is a command-line tool with no sign-in. The sweep here is every acceptance criterion as a journey (EVAL-001 to EVAL-009) plus an app-wide smoke of the commands that read every record (EVAL-010). Commands that do not read a record's track or phases (`init`, `onboard`, `hooks`, `ui`, `learn`, `update`) were not driven; they are listed in results.md as not swept.

## Method
Each journey runs the worktree's CLI (`ruby -Ilib exe/soft-foundry`) as a separate process in a throwaway git repository carrying a copy of this repository's `.ai/`, with colour off, no terminal, and provider keys and `SOFT_FOUNDRY_PHASE` unset. A person's and an agent's actions are commands: `change new`, `phase seal`, `phase reopen`, `gate`, `change status`, `change size`, `change close`. The work inside a phase is reduced to its record by the phase-completion fixture the test suite and harness evals share (templates filled, handoff complete at HEAD); every phase is then sealed with the real `phase seal`, so the commits, the lock and `current_phase` are the tool's own. The scripts are `evidence/lib.rb` and `evidence/journeys.rb`; each transcript is `evidence/EVAL-NNN.txt`.

## Personas
- Maintainer: creates a change, chooses its track, approves the must criteria, decides at the remediation cap, merges and closes.
- Agent: works the phases the track requires and seals each.
- Reader: opens the help text, `.ai/workflow.yml` and the skills to learn what the light track is.

## Journeys
| EVAL | Criteria | Requirements | Starting state | What is done | What is asserted |
| --- | --- | --- | --- | --- | --- |
| EVAL-001 | AC-001 (must) | REQ-001, REQ-002 | New repository, branch change/l1 | `change new --track light`, medium risk; six required phases worked and sealed in order; `gate all`; merge; `gate all`; `change close`. Then the same six phases on a gated record. | Each seal advances to the next required phase; no check fails; the six track-optional phases are skipped; the change closes. The gated twin is refused at `phase seal specify`, fails `gate all` on predecessor complete, and is refused by `change close`. |
| EVAL-002 | AC-002 (must) | REQ-003, REQ-004 | Sealed light and gated records | Remove the must approval; edit the specification after its seal; run two remediation rounds, ask for a third, record a third anyway; declare risk high on a light record. | Each state fails the same named check on both tracks; the high-risk light record fails track permitted and cannot be sealed. |
| EVAL-003 | AC-003 (must) | REQ-005 | Light record under rules 2 through review, lib/app.rb modified by the change | A review finding marked outside_change with each of the six spellings, then with an unmodified path. | `gate review` exits 2 on outside-change findings naming the path, six times; the unmodified path passes. |
| EVAL-004 | AC-004 (should) | REQ-006 | Light record through review | One remediation sealed and reopened; one started and reopened before completing; a second sealed; a further reset requested. | The unfinished one is not counted; the refusal says rounds and gives the count. |
| EVAL-005 | AC-005 (should) | REQ-007 | Light record with intake and specify sealed | Commit README.md, docs/guide.md, a record file and review/SKILL.md; `change size --phase verify`; then add lib/app.rb. | Smaller size with a documentation-only reason; largest size once lib/ is touched. |
| EVAL-006 | AC-006 (should) | REQ-008 | Repository at the evaluated commit | Read the review and adversarial-testing skills. | The two statements the criterion names are present. |
| EVAL-007 | AC-007 (should) | REQ-009 | Repository at the evaluated commit | Read `soft-foundry help` and the tracks section of `.ai/workflow.yml`. | Each names the track, its required phases, the locks kept and the high-risk exclusion. README.md and docs/user/ are outside this skill's read set and are not evaluated. |
| EVAL-008 | AC-008 (should) | REQ-010, REQ-012 | Light record with three phases sealed | `change status` with colour off, then with every non-ASCII character removed; `--json`. | Track shown; each stepped-over phase labelled in words; lines read correctly without symbols. |
| EVAL-009 | AC-009 (should) | REQ-011 | New repository | `change new --track nosuch`; `change new` with no track; `--track iterative`; a gated record through all twelve phases to close; a record with no rules or track line. | Refusal lists the three tracks; other tracks and older records behave as before. The suite and harness evals were run by verification (CHECK-001, CHECK-005) and `ci` was run again here. |
| EVAL-010 | AC-001, AC-009 | REQ-002, REQ-011 | One closed and one open light record | `check`, `change list`, `scan`, `gate all`, `gate evaluate`, `change size --phase evaluate`, `phase run verify --dry-run`, `ci`. | Every command answers and none fails because a track-optional phase is pending. |

## UI walkthrough evidence
There is no browser UI in this change. The equivalent evidence is the command transcripts under `evidence/`, which record each command, its output and its exit status at every state transition.

## Accessibility interaction
Applicable (`surfaces.accessibility: true`); the surface is command-line output and Markdown.
- Keyboard-only operation: every journey was driven by commands with flags and no terminal attached; no command prompted.
- Focus order and visible focus: not applicable to line-oriented output.
- Error identification: each refusal and failing check exercised was read for a named cause and a next step (EVAL-002, EVAL-003, EVAL-004, EVAL-009).
- Screen-reader readable output: EVAL-008 removes every non-ASCII character from `change status` and checks the lines still carry the outcome and the reason in words; all journeys ran with `NO_COLOR=1` and the output was checked for escape sequences.
- Markdown heading order of the new documentation is under docs/, outside this skill's read set; it is left to review.
