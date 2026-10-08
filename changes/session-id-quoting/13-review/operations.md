# Operations Review

## Scope reviewed

`.ai/rules/observability.md` and `12-observability/`. That phase is still pending, which is allowed: it is optional, and `surfaces.observability` is false. This review does not fill it.

`.ai/repository.yml` marks failure detection, health, operational visibility, and alerting NOT_APPLICABLE because there is no production service. The maturity dashboard baseline applies when infrastructure as code is provisioned. It is not provisioned here.

The operational surface of this change is the local CLI and the loopback UI, both already shipped with the session ledger.

## Findings

None.

## What holds

A rejected ledger line is not a new production outage. Lookup skips it and continues. `resume` with no trusted match exits non-zero and prints `resume: no recorded session for change <slug>` plus the command to list sessions. That message does not include the rejected id. `sessions` exits 0 and reports how many trusted sessions are recorded. Both are existing, local, and visible in the terminal without a new metric.

No credential is added to a log. Prompt masking on write is unchanged. The version bump is `0.18.1` with no migration. Rollback is reverting the gem; old ledgers remain readable, because the filter only hides lines `record` would not have written, and real ids are still printed unchanged.

The standard-dashboard rules (golden signals, RED, USE, an alarm per resource) have no resource to attach to.

## Conformance

N/A for a deployed service, alarms, and a dashboard. The local failure mode is visible through the CLI's existing exit code and sentences, which is the detection path this repository uses. No blocking finding.
