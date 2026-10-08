# Operations Review

## Scope reviewed

Operator-visible behavior of `phase run` for review and judgment: the `shell:` line, the `! warn shell:` line, the same-provider advisory, and the `findings explained` gate line. `surfaces.observability` is false. There is no deployed service. `12-observability/` is still the pending template, which is allowed: the phase is optional and this change adds no production process. Compared with `.ai/rules/observability.md` and `.ai/rules/errors.md`.

## Findings

None. The launch warning's wrong reason is REV-FUN-001, on the functional review. It is not a second defect.

## What was checked

- **Choice is visible.** A differing shell prints one `shell:` line on standard output before the session starts. No differing installed shell, or an unresolvable provider, prints one `! warn shell:` line on standard error and still names `--shell`.
- **Same-provider review is visible after the fact.** When the completed review records a canonical provider that matches implementation or remediation, `same_provider_notices` prints an advisory and the gate still passes. That is the detection path `.ai/rules/observability.md` asks for on a local CLI: the person sees it on `phase run`, `gate`, `change status`, and `change close`. It does not fire when the provider string does not normalize, which attack already recorded.
- **REV-FUN-001's warning does not name the collision.** In the probed input the warning says remediation's provider is not recorded and then starts claude, which is implementation's provider. The operator is told to pass `--shell`, not that the shell just chosen is anthropic. After that session, an honestly recorded `provider: anthropic` still produces the same-provider advisory. The session has already run on the implementer's provider.
- **No new alarm or dashboard.** A library gem with no service does not gain a failure mode that a dashboard would detect. The lines above are the operator surface.

## Conformance

Conforms. The new lines and the advisory are the operational signals, and they behave as specified on the inputs the tests cover. REV-FUN-001 is the case where the launch warning names the wrong fact. No production metric or alarm is owed.
