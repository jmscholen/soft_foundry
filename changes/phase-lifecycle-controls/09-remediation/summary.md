# Remediation

Second round, after the BLOCKED judgment at `2da13ad`. The first round (ATK-001..003, commit `529e749`) is unchanged and still stands.

## Finding references
REV-001 (major) and REV-002 (major) from 13-review, returned by 14-judgment. Not changed: REV-003 (D3, accepted by review), REV-004 (docs/user and harness-eval cases: outside this skill's write set), REV-005, REV-006, REV-007, EVAL-F1..F5 (minor; left for a person), ATK-004's hand-edited non-empty timestamp (TB-3), ATK-005, ATK-006.

## Root cause
- REV-001: `ChangeRecord::Transaction#commit!` renamed `metadata.yml` first. A crash after that rename and before the handoff renames left `phase_reopenings` recording a reset while the handoffs stayed `complete`, and `change close` decides from handoff status, so it could succeed on evidence the history says was reset.
- REV-002: "discharged" was Ruby/JS truthiness of `discharged_at`. `""` was discharged in `open_release_items`, `change close`'s confirmation list and the timeline, and open in the released table; `Release.lint` allowed it.

## Changes made
- `Transaction#commit!` stages and renames handoffs first and `metadata.yml` last. A crash between renames now leaves reset handoffs with no history entry; close refuses a pending phase, so it cannot succeed on stale evidence. Staging failure still leaves the record byte-identical. The comment on `ChangeRecord#transaction` says so.
- `ChangeRecord.discharged?(item)`: discharged only when `discharged_at` is a timestamp or a non-blank string. Used by `open_release_items`, `Release#discharge`, `Cli#change_close`'s confirmation list and the timeline in `snapshot.rb`. `releaseSection` in `ui/assets/app.js` uses the same test, so the CLI, `ci` and the page agree.
- `Release.lint` refuses a present, non-nil, blank `discharged_at`, naming the item.
- Tests: `test_a_crash_between_renames_never_leaves_history_for_a_reset_the_handoffs_do_not_show` (`test/phase_reopen_test.rb`, injects a failure on the metadata rename) and `test_a_blank_discharged_at_is_open_and_lint_refuses_it` (`test/release_state_test.rb`). I did not run them red before the fix, so there is no red commit for them (as VER-002).

## Not changed, with reason
`docs/` and `.ai/` (including harness-eval cases) are outside this skill's write set, so REV-004 and REQ-027 stay for the document phase and a maintainer. Minor findings above are not blockers per the judgment. The `app.js` change was not rendered in a browser.

## Evidence invalidated
Implementation changed (`lib/soft_foundry/{change_record,release,cli,snapshot}.rb`, `lib/soft_foundry/ui/assets/app.js`, two test files). Verification, evaluation, attack, review and judgment evidence is stale.

## Required reruns
Verify, evaluate, attack (re-drive a kill between renames and a blank `discharged_at` through `ci`, `change close` and the page), review, judge.
