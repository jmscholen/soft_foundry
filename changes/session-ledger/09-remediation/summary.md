# Remediation

## Finding references
- **REM-001 (major).** The review phase's first run, `soft-foundry phase run review --shell grok -- --always-approve` at 1abc499, exited 2 before any work: Grok reported "a value is required for '--single <PROMPT>' but none was supplied". The runner built `grok -p -s <id> --always-approve <prompt>`; Grok's `-p` takes the prompt as its value, so it read `-s` as a missing value. The same fault existed before this change whenever extra arguments followed `-p` (the 0.17.1 form `grok -p <extra> <prompt>`). The unit test encoded the same wrong order, so only the live run exposed it. The aborted run's handoff and metadata edits were restored from the index; no review work was produced.
- **EVAL-OBS-001 (minor).** On the change page the resume command ran on directly after the first prompt's text.
- **FIND-ATK-001, FIND-ATK-002 (minor).** The 1 MB payload limit and the control-character folder case were undocumented.

## Root cause
REM-001: the launch arguments for Grok were written from its help summary ("`grok -p` is its single-turn headless form") without checking that `-p` is an option taking a value; the live checks during intake used `grok -p "<prompt>" -s <id>`, which happens to work, and the runner's order was never run live before review.

## Changes made
- RED `88eee99`: `test/cross_cli_hooks_test.rb` now asserts `["-s", <id>, "--always-approve", "-p", <prompt>]` and the matching dry-run line; it also reopened 06, 07, and 08 (handoffs to `in_progress`) in the same commit.
- GREEN `93acd89`: `lib/soft_foundry/phase_runner.rb` builds `grok -s <id> <extra...> -p <prompt>`; `ui/assets/app.js` puts "Resume:" and the command on their own line; `README.md` states the 1 MB limit and the control-character folder case.
- Checked live after the fix: `grok -s <uuid> --always-approve -p "Reply with only the word ok."` answered and `grok sessions search` found the session under that ID.

## Evidence invalidated
Verification, evaluation, and attack evidence bound to 98b55d1 (all three handoffs set to `in_progress` in 88eee99).

## Required reruns
Verification (full), evaluation (all journeys, plus one running the runner's exact Grok launch live), attack (all cases). Review then runs again through `phase run review --shell grok`.
