# Operations Review

## Scope reviewed
What an operator or agent sees and does differently: `check` may now report content findings; every complete phase gate prints `content clean`; `scan` exists; a policy file may need an entry; the security rule asks for the marker on quoted attacks.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-018 | info | `README.md`, `.ai/README.md`, `.ai/schemas.md`, `.ai/rules/security.md`, the policy comment | Documented where an operator and an agent each read, with the levels in a table and both exemption paths named. | `.ai/rules/general.md` |
| REV-019 | info | this repository | The first repository-wide scan found a canary in a closed record and nothing else; the exemption is recorded with its reason; the open records all print `content clean`. | `.ai/rules/general.md` |
| REV-020 | minor | rollout | `scan` is on-demand and `ci` runs `check` (control plane only) plus gates (open records only); a secret in a *closed* record's evidence is found only by `scan`. Follow-up: run `scan` in `ci` as well, or at least over closed records' evidence. | `.ai/rules/observability.md` |
| REV-021 | info | `README.md` Maturity assessment section (pre-existing) | Still documents `--maturity=scan`. Unchanged. | Document rules |

## Conformance
Conforms.
