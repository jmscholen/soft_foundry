# Consolidated Review

Reviewed at `d08f74e79af9408d0d34524b803ffc57ae279911`. Library and tests are the implementation commit `6f753070e06ed9eb74b9744541b409429f81afa8`. Rules applied: the implementation baseline (`general`, `architecture`, `security`, `errors`, `dependencies`, `observability`, `git`, `learned`), plus `ruby` and `testing`. No framework, database, or infrastructure-as-code tool applies. Accessibility and policy conformance are in their own files.

## Functional

Conforms. REQ-SQ-001: every lookup goes through `entries`, which drops a line `record` would not have written, and leaves it in the file. REQ-SQ-002: `resume_command` shell-quotes the session id; real ids are unchanged. REQ-SQ-003: version `0.18.1`. The RED quoting expectation fixed in the implementation commit is approved: the old double-quoted literal did not match either the vulnerable string or the quoted string, and the replacement matches only the quoted string.

## Architecture

Conforms. One check on the existing read path, one quote on the existing command builder. No new dependency or abstraction. The comment on `trusted?` oversells how much of `record`'s write path is re-checked; the predicate matches the requirement.

## Security

Conforms. Shell metacharacters in a ledger id are not returned and, if `resume_command` is called anyway, are quoted. The agent value is not concatenated into the command. The page shows the command as text. REV-SEC-002 and re-stripping of hand-edited prompts are out of scope and unchanged.

## Accessibility

Conforms. Declared surface. Command prefixes, status words, and the recorded-sessions text node are unchanged. Normal ids print as before. No finding. Details and the criteria cited are in `accessibility.md`.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms are NOT_APPLICABLE in `.ai/repository.yml`. Nothing new is collected, shared, or retained. No policy text change is owed.

## Infrastructure

N/A. No infrastructure-as-code tool is recorded, and the diff touches none.

## Operations

N/A for a deployed service. A rejected line is skipped locally; `resume` still exits non-zero and names the next command when nothing trusted matches. No new alarm or dashboard is owed. The observability phase has not run and is optional.

## Blocking findings

None.

## Residual concerns

- An id that matches `SessionLedger::ID` and starts with a hyphen (`--help`, `-rf`) is trusted and pasted unchanged. `Shellwords.escape` does not neutralize a flag-shaped argument. `record` already accepts that alphabet. The real agent CLIs were not run, so the effect is not established. It is not a shell breakout.
- A line that passes `trusted?` is still shown with whatever `cwd` and prompt text are stored. Control-character stripping happens on write, not again on read. Out of scope for REQ-SQ-001.
- When the file has only rejected lines, `sessions` says `0 recorded` and suggests fewer search words (EVAL-OBS-001). That matches the decision to skip without a warning.
- Verification, evaluation, and attack were recorded by the session that implemented the change. This review re-read the code, re-ran `test/session_id_quoting_test.rb`, and probed `trusted?` and `resume_command`. It did not re-run the full suite or the attack shell.

## Unresolved findings

None.
