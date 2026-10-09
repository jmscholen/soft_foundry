# Functional Review

Reviewed at `661b454` (panel code identical to `4f3b2da`). Requirements are REQ-PN-001..010 in `00-intake/request.md`. The committed verification suite was not re-run; the snapshot, agreement, and rerun cases below were run in a throwaway repository against this tree.

## Scope reviewed

`lib/soft_foundry/panel.rb`, `panel_run` and `spawn_panel` in `lib/soft_foundry/cli.rb`, `PhaseRunner#refusal`, the panel section of `README.md`, and the REM-003 tests in `test/panel_remediation_test.rb`. Compared with the threat-model mitigations and with the verification, evaluation, and attack records at this commit.

## Closed on the inputs from the third review

Reproduced in the fixture. Each of these now exits non-zero, prints `✗ fail panel:`, and does not park the change.

| ID | What was run | Result |
| --- | --- | --- |
| REV-SEC-007 | Argument stage replaces `02-specification/handoff.yml` | Exit 1, `panel.outcome` `failed`, status `blocked`, the line names `handoff.yml` |
| REV-SEC-008 | Argument stage replaces `lib/app.rb` during the run | Exit 1, outcome `failed`, the line names `lib/app.rb`. The bytes are left in place; see REV-SEC-015 |
| REV-SEC-009 | Both independent drafts are the same bytes | Exit 1, identical-draft failure, no argument round |
| REV-SEC-010 | Argument stage adds `02-specification/.hidden` | Exit 1, the line names `.hidden` |
| REV-FUN-006 | Split, and the consensus also writes `lib/app.rb` | Exit 1, status `blocked`, metadata stays `in_progress` |

REQ-PN-001 (membership, refusals, round bounds, `--shell` rejected), REQ-PN-003 (agreement taken only from the bytes appended on that member's turn), REQ-PN-004, REQ-PN-005 (a clean split parks; a failed run does not), REQ-PN-006, REQ-PN-008, REQ-PN-009, and REQ-PN-010 (README, help, schemas, human-boundaries, version `0.20.0`) match the code and the tests recorded in `06-verification/results.md`.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-SEC-011 | major | `lib/soft_foundry/panel.rb` `staging_for`, `identical_drafts` | A member can read the other draft in the system temp directory and change one byte. The identical-bytes check then passes and the panel completes. | Independent stage, grok-1. Both `soft-foundry-panel-*` directories already exist under the system temp directory before either member writes. grok-1 reads the other `draft.md` and writes those bytes plus one newline. Exit 0, `panel.outcome` `agreed`, `panel.failures` empty, status `complete`. The stored drafts differ only by that newline. | REQ-PN-002 |
| REV-SEC-012 | major | `lib/soft_foundry/cli.rb` `spawn_panel`; `Panel#repository_snapshot` | The repository comparison runs when the member process exits. A detached child can change a tracked file after the handoff already says agreed. | Consensus member double-forks (`Process.setsid`) and, once `handoff.yml` contains `outcome: agreed`, writes `lib/app.rb` as `puts :planted`. `spawn_panel` waits only for the direct child. Exit 0, `panel recorded` passes, `panel.failures` empty, status `complete`. After the command returns, `lib/app.rb` is `puts :planted`. | REQ-PN-002, THREAT-002; README statement that anything else fails the run |
| REV-SEC-013 | major | `Panel#repository_snapshot` (`git ls-files -co --exclude-standard`) | A file under `.git/` is not in the snapshot. An argument-stage write of a commit hook is kept, and the panel agrees. | Argument stage, claude-1, writes an executable `.git/hooks/pre-commit`. `git ls-files` does not list it. Exit 0, outcome `agreed`, failures empty, status `complete`, and the hook is still that script. The next `git commit` runs it. | THREAT-002 |
| REV-SEC-014 | major | same snapshot; `Guard.mode` | A gitignored machine-local guard override is not in the snapshot. Quoted `mode: "off"` turns the guard off for later sessions on this checkout. | Argument stage writes `.soft-foundry/enforcement.yml`. The file is gitignored, `git ls-files` does not list it, and the panel exits 0 with outcome `agreed`, failures empty, and status `complete`, file still present. `Guard.mode` on a file whose YAML is `mode: "off"` returns `off` from the machine-local override. Later guard calls allow every tool call and say nothing. Unquoted `mode: off` is a YAML boolean and does not match; the quoted form does. | THREAT-002; `.ai/rules/security.md` (a security control is not disabled without an exception) |
| REV-SEC-015 | major | `Panel#run` baseline; `PhaseRunner#refusal` | A caught write is not restored. The phase stays runnable, and the next run treats the planted bytes as the baseline. | Argument stage writes `lib/app.rb` as `puts :planted`. That run exits 1 and names the file. The bytes stay. Refusal allows another run while the handoff is `blocked`. A second panel whose members never touch `lib/app.rb` exits 0, outcome `agreed`, failures empty, status `complete`, and `lib/app.rb` is still `puts :planted`. | THREAT-002 |
| REV-FUN-007 | minor | `Panel.agree_line`, `Panel.normalize` | Nothing checks that an `agree:` line is one sentence. | Both members append the same paragraph. The panel agrees. The person does not get the one-sentence outcome REQ-PN-003 describes. Seen live as EVAL-OBS-001. | REQ-PN-003 |
| REV-FUN-008 | minor | `Panel#run` argument loop; `CLI#run` rescue | Deleting `ARGUMENT.md` on a turn the guard allows is an unhandled `Errno::ENOENT`, not a panel failure. | Argument stage, first member deletes `panel/ARGUMENT.md`. The round is only warned as spoiled. The next turn's `File.read` raises. The CLI prints `soft-foundry: No such file or directory @ rb_sysopen` and exits 1. The handoff stays `pending` with no `panel:` block and no `✗ fail panel:` line. | REQ-PN-003; `.ai/rules/accessibility.md` (outcome word; error says what to do next) |
| REV-FUN-009 | minor | `Panel#run` consensus return | A consensus-stage failure does not set `panel.outcome` to `failed`. | Consensus writes `lib/app.rb` after the members agreed or split. Status becomes `blocked` and the command exits non-zero, but `panel.outcome` stays `agreed` or `split`. An argument-stage failure of the same kind records `failed`. | REQ-PN-005 |
| REV-FUN-002 | minor | `test/panel_phases_test.rb` `test_shell_args_reach_only_their_shell` | `--shell-arg` is covered, and that test shares the GREEN commit `d1cf0d6`. It has no RED commit of its own. | A regression in per-shell arguments would not show as a red-then-green pair. Implementation deviation 2. | `.ai/rules/testing.md` |

## Conformance

Does not conform. REQ-PN-002 does not hold for REV-SEC-011. The runner check REM-003 added, which the README states as "anything else fails the run", does not hold for REV-SEC-012, REV-SEC-013, REV-SEC-014, or REV-SEC-015. The other panel requirements hold for the inputs the committed tests and this review actually ran.
