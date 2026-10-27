# Implementation Log

## Changes made
Test first: commit e496c67 ("RED: ...") holds the failing tests for all four code features (`test/display_test.rb`, `test/cli_change_new_options_test.rb`, `test/phase_run_blocked_marking_test.rb`, `test/cli_change_summary_test.rb`, `test/protection_stated_test.rb`). Every one failed before any implementation existed. The GREEN commit follows it.

1. Escaper: `lib/soft_foundry/display.rb` (`Display.safe`, `Display.list`). Control, format (zero width, bidi) and line/paragraph separator characters become `<U+XXXX>`; lists truncate with a count. Used by the `blocked:` warning, the summary and the vocabulary refusal.
2. `change new --type/--risk` (REQ-001..003): `ChangeRecord::TYPES`, `RISKS`, `vocabulary!`; `ChangeRecord.create(type:, risk:)` validates exact values before anything is created, refuses a risk whose forced track differs from the chosen one, and writes the values by text edit so template comments survive. `cli.rb` parses the flags and the usage text lists the vocabularies. `Check#check_vocabulary` lints the constants against the `type:` and `risk:` comments in the metadata template and the risk names in `workflow.yml`.
3. Blocked marking (REQ-004..006): `PhaseRunner#mark_blocked!(phase)` under the record lock changes only `status` and `notes` of the handoff of the phase the runner was given. `cli.rb#mark_blocked` prints `blocked: <phase> has N blocking item(s)...` or a `warn:` line on failure; called at the single-run site (which then exits 2) and the parallel site. The auto-reopen path reaches the same single-run site.
4. `change summary [slug]` (REQ-008, 009, 017): `lib/soft_foundry/change_summary.rb` reads metadata and handoffs with a 256 KB cap and aliases disabled, prints `change:`, `phase:`, `phase-status:`, `findings:`, `blocking:`, `owed:`, `note:` lines, all text through `Display`. Dispatch and slug check in `cli.rb#change_summary`. Never calls the gate, never writes.
5. Access-control parity gate check (REQ-012..014): `Gate#protection_check`, registered for verify only, named `protection stated`. Skipped when the profile declares no `access_control` or no changed path since the plan matches; otherwise requires one `in_force` check, or every check stating a value with a note; `disabled` always needs a note; invalid values and unreadable globs fail.
6. `lib/soft_foundry/version.rb` 0.21.0 to 0.22.0.

## Decisions
See decisions.md.

## Deviations from plan
Control-plane and documentation text could not be written by this phase; see deviations.md.

## Challenges
- The runtime guard blocked Bash commands containing the bare word `docs` (the type vocabulary) because DOCS is denied to this skill; file edits were made with the edit tools instead. No challenge file needed.
