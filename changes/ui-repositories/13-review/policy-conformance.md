# Privacy and Security Policy Conformance Review

Standard: `.ai/rules/policy-conformance.md`. Cite the policy document and clause, or a rule from that file, in every finding.

## Documents checked
This repository's `policies:` block in `.ai/repository.yml`: privacy, security, and terms all NOT_APPLICABLE with rationale. There is no published text to check a clause against.

## Scope reviewed
`surfaces.policy` is false for this change. Examined: what is read (records of every repository with something running), what is kept (a list of repository paths in memory for the server's life; a token in the tab's session storage), and where it goes (the loopback page, behind the token). No outbound request is added.

## Findings
| ID | Severity | Location | Finding | Policy clause or rule |
| --- | --- | --- | --- | --- |
| REV-026 | info | reach | The page gathers what a person is working on across repositories into one place. It is their own data on their own machine, shown to whoever holds the link. | Rule: data minimisation |

## Policy text changes required
None.

## Conformance
N/A, with the statement above of what was examined: `surfaces.policy: false` is correct.
