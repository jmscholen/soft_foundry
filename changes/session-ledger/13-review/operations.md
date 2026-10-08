# Operations Review

## Scope reviewed

`.ai/rules/observability.md` and `.ai/rules/errors.md`, the specification's failure and observability sections, `12-observability/` (still the untouched template; the phase is optional and `pending`), doctor, the hook command, README's failure notes, and rollback in `04-plan/rollback.md`.

There is no production service. `.ai/repository.yml` marks failure detection, health, operational visibility, and alerting NOT_APPLICABLE for that reason. The new operational surface is a CLI on the maintainer's machine.

## Findings

None.

## What was checked

**The hook fails open on purpose.** `session_log` rescues `StandardError` and `ScriptError`, prints nothing, and exits 0. The installed command also sends both streams to `/dev/null` and ends with `exit 0`, with a 10-second hook timeout. REQ-SL-005 and the specification require that, including the consequence that a fault is invisible. `.ai/rules/errors.md` would otherwise forbid the swallow. The specification is the exception, and it names the detection path: `sessions` shows nothing new, and README says to run `doctor`.

**What doctor actually reports.** The session line is `warn` when no agent has the hook, and `pass` with the agent list when at least one does. It does not change doctor's exit code (REQ-SL-010). It reports install state, not "the last record succeeded". A hook that is installed but cannot write (disk full, a chmod the user cannot explain, a relative `SOFT_FOUNDRY_SESSIONS`) stays silent. That gap is the specified design, not an unimplemented alarm. REV-SEC-002 is the case where the override itself causes the bad write.

**Growth.** The ledger is not pruned. The specification says about 1 KB per session and leaves pruning out. README says delete the file to forget it. Uninstall does not delete it, and says so.

**Rollback.** `04-plan/rollback.md` is uninstall plus deleting the ledger file. Install is marker-scoped, so uninstall does not take other hooks with it (AC-011, EVAL-001). No migration, no remote state.

**Runner.** A Grok or Claude run records `executed_by.session_id` and `cwd` before the process starts, so a killed session still names what to resume. Codex stays null when the hook did not see a row. EVAL-008 confirmed the Grok path live.

**Phases not run.** `10-user-documentation`, `11-faq-index`, and `12-observability` are optional and still `pending`. REQ-SL-015's user-facing description is in README and help, and evaluation checked it. This review does not treat the unstarted optional phases as a defect. Judgment can still ask for them.

The standard-dashboard half of `observability.md` does not apply: nothing is provisioned as code.

## Conformance

Conforms. The new failure mode the specification accepts (a silent hook) has the detection path the specification names. No production alarm or dashboard is owed.
