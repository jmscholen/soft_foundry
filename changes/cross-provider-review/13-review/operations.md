# Operations Review

## Scope reviewed

`.ai/rules/observability.md` and `.ai/rules/errors.md` for a library with no deployed service. `surfaces.observability` is false. The observability phase is still pending; it is optional, and there is no service to alarm on. The operator surface is the CLI.

## Findings

None.

## Failure modes and how they are seen

- The chosen shell is not logged in or fails to start. The child exits non-zero and the runner prints `{shell} exited {status}`, then runs the gate. Intake records this as a non-goal: "installed" means on `PATH`, not logged in. EVAL-OBS-001 is that case for Codex on this machine. `--shell` is the recovery. No new silent success.
- No installed shell is on another provider. `! warn shell:` on stderr names the providers and the shell that will be used. The same-provider advisory fires again after the phase completes, if the handoff's provider matches.
- A named phase's provider is not recorded, and another shell is on a different known provider. `! warn shell:` names the missing phase and the provider the choice differs from. Probed.
- A review finding above minor has no `failure:`. `findings explained` fails and names the finding ids.

`Shell.resolve` raises when the command is not on `PATH`. `default_shell` treats that raise as "not installed" (`rescue nil`) and either picks another allowlisted shell or warns and uses the first. The not-installed result is the predicate. An unexpected exception from the path check would take the same path; that input is not one the requirement describes, and the warning still fires when no alternative shell remains. Not filed.

No metric, dashboard, or alarm is owed. Nothing is deployed.

## Conformance

Conforms for a library. The new failure modes are visible on stdout or stderr with a status word, and the gate reports a missing `failure:`. The pending observability phase does not leave a deployed failure undetected, because there is no deployed service.
