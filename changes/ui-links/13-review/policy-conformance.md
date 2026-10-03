# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy, security, and terms all NOT_APPLICABLE with rationale. There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change. Examined: the popups show data the page already shows; nothing is collected, stored, or sent.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-018 | info | popups | No new data. | Rule: data minimisation |

## Policy text changes required
None.

## Conformance
N/A, with the statement above of what was examined: `surfaces.policy: false` is correct.
