# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy, security, and terms all NOT_APPLICABLE with rationale. There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change. Examined: what the new views display (workflow configuration, recorded times, the spend ledger) and that nothing new is collected, stored, or sent anywhere.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-018 | info | timeline | Names recorded in a change (who vetted, who decided) are displayed to the local viewer as recorded. | Rule: data minimisation |

## Policy text changes required
None.

## Conformance
N/A, with the statement above of what was examined: `surfaces.policy: false` is correct.
