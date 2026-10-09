# Operations Review

## Scope reviewed

This is a local CLI. `surfaces.observability` is false, and `12-observability/` is still the pending template, which matches that: there is no deployed service, metric, or alarm to add. What an operator has instead are the `panel:` / `fail panel:` / `warn panel:` lines, the exit code, and the handoff (`status`, `panel.outcome`, `panel.failures`, `blocking`). README's panel section is the runbook. Compared those signals with the failures reproduced in the security review.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-SEC-012 | major | `spawn_panel` and the post-exit window | The operator's fail line never fires for a write that lands after the member process has exited. | See the security review. The command exits 0 and prints `✓ pass panel: agreed` and `✓ pass panel recorded`. `lib/app.rb` changes after that success. Nothing in the handoff names the file. | `.ai/rules/general.md` (a failure mode needs a practical way to detect it); README "anything else fails the run" |
| REV-SEC-013 | major | snapshot coverage | A hook under `.git/hooks` is invisible to the only detector the operator has. | The panel exits 0 and agrees. The next commit, which is how this phase gets recorded, runs the hook. No fail line. | Same |
| REV-SEC-014 | major | snapshot coverage | A gitignored `.soft-foundry/enforcement.yml` is invisible to that detector. | The panel exits 0 and agrees. With quoted `mode: "off"`, later guard invocations on this checkout do not refuse and do not log. | Same; `.ai/rules/security.md` |
| REV-SEC-015 | major | no restore before the next run | The first run does name the file and exits 1. The recovery an operator actually has (run the phase again; a `blocked` handoff is not refused) reports success and leaves the planted bytes. | First exit 1 names `lib/app.rb`. Second exit 0, `pass panel: agreed`, file still `puts :planted`. The success line is then a false all-clear. | Same |

REV-FUN-008 is the operations face of the deleted-argument crash: exit 1, a Ruby path in `soft-foundry:`, handoff left `pending`, so `soft-foundry ps` / a later status check does not show a panel failure. Minor, recorded in the functional review.

No production dashboard or alarm is missing, because nothing is deployed.

## Conformance

Does not conform for the operator contract REM-003 documented. Synchronous git-visible writes do produce `✗ fail panel:` and a non-zero exit (re-checked). REV-SEC-012, REV-SEC-013, and REV-SEC-014 produce the success lines instead. REV-SEC-015 produces a success line on the retry.
