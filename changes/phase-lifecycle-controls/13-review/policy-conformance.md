# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked

The change declares `surfaces.policy: false`. The documents recorded under `policies:` in `.ai/repository.yml` (profile assessed 2026-10-22, commit `fb74c5fe`) are:

- Privacy: status `NOT_APPLICABLE`. No document path. Rationale in the profile: library gem with no users' data; outbound calls are provider model listings and the RubyGems version check; the optional session index stays on the user's machine.
- Security: status `NOT_APPLICABLE`. No `SECURITY.md`. Rationale: maintainer decision of 2026-09-15 in `changes/security-policy-not-applicable`, vulnerability reports go through GitHub issues.
- Terms: status `NOT_APPLICABLE`. No document path. Rationale: no service is offered; the gem is distributed under its RubyGems listing.

No published privacy policy, security policy, or terms text was compared clause by clause, because the profile records none.

## Scope reviewed

Examined what this change writes and passes on: reopen reasons, release item descriptions, discharge notes, and `--env` values. Reasons, descriptions, and notes are stored in the change record on disk. `--env` values are placed in the child process environment and are not written to the record, handoffs, or command output (REQ-012). The diff does not add a form, a log of a person's data, a new recipient, a retention period, or a promise about authentication or disclosure. The session index described in the privacy rationale is unchanged by this diff.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Policy clause or rule |
| --- | --- | --- | --- | --- | --- |
| None |  |  |  |  |  |

## Policy text changes required

None

## Conformance

N/A. `surfaces.policy` is false. The three `policies:` entries, the branch diff, and the data the new commands store or pass through were examined. The change does not alter what the application collects, shares, retains, protects, or promises about a person. An `--env` value can be a credential the operator already holds; keeping it out of the record is an engineering rule (REQ-012), and there is no published policy clause that would have to change for that behavior to stay honest.
