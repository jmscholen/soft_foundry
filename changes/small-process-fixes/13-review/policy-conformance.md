# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

Recorded under `policies:` in `.ai/repository.yml` (profile assessed 2026-10-22, commit `fb74c5fe`, refreshed by discovery for this change at `07ec16c` without a profile edit):

- privacy: status NOT_APPLICABLE. Rationale in the profile: library gem, no users' data transmitted. No `PRIVACY*` file at the repository root.
- security: status NOT_APPLICABLE. Rationale: maintainer decision of 2026-09-15 in `changes/security-policy-not-applicable`; no `SECURITY.md`. Vulnerability reports go through the public repository's issues.
- terms: status NOT_APPLICABLE. Rationale: no service is offered. No terms file at the repository root.

Discovery recorded the absence as established. These are not published documents a change can contradict. The absence is the recorded answer for this library, not a gap this change opens: the change adds no collection of personal data.

## Scope reviewed

`surfaces.policy: false`. Compared the diff and REQ-018 with the three profile entries and with the kinds of change the standard lists (new collection, new recipient, retention, purpose, security promise, consent or rights).

The diff adds local CLI behavior, a local file read of the change record, a local handoff rewrite, guidance text, and a structure check on `tests.yml`. It does not add a network call, telemetry, a cookie, an account, a log of a person, a new recipient of user data, or a change to retention. The optional session index under `~/.soft-foundry/` is pre-existing and untouched. Provider API keys are unset in the verification run and are not read by the new code.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Policy clause or rule |
| --- | --- | --- | --- | --- | --- |
| | | | None. | | |

## Policy text changes required

None.

## Conformance

N/A. `surfaces.policy` is false. The diff, the three `policies:` entries, and the repository root were examined. The change alters nothing the application collects, shares, retains, protects, or promises in a published privacy policy, security policy, or terms. No clause has to be published.
