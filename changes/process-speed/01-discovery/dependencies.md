# Dependencies

## Internal dependencies
- `PhaseReopen` depends on `ControlPlane#downstream` and `ChangeRecord#transaction`; the cap and a narrower reset must keep reset and history atomic.
- `Gate` checks depend on `ChangeRecord` (metadata, handoffs, judgment evidence) and `Git` (recorded commits). New checks follow the `HISTORICAL` skip for closed and released records.
- `PhaseRunner` auto-reopens stale phases through `PhaseReopen` (source `auto`); a cap applied in `PhaseReopen` must not refuse an automatic staleness reopen of a non-remediation phase.
- `Advisory`, `ChangeSummary` and `Snapshot` (UI) read `status` and `human_decisions` and must show a parked change consistently.
- `check` lints `workflow.yml` keys and harness-eval cases; new keys need lint rules.

## External services and libraries
- Ruby 3.3.1 stdlib (`yaml`/Psych, `digest`, `time`), minitest, rake, bundler. No new gem is expected.
- The `git` CLI through `SoftFoundry::Git`.
- Provider CLIs (claude, codex, grok) only through `phase run`; unaffected.

## Infrastructure dependencies
N/A: no deployed service, database or IaC. CI is GitHub Actions running `soft-foundry ci` and the suite.
