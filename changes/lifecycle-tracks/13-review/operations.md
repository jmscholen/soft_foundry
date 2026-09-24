# Operations Review

## Scope reviewed
What an operator or agent sees and does differently after this change: `--track` on `change new`; the track line on `change new` and `change status`; `change vet` and `change reopen`; the three new gate checks and how each says what to do next; the `check` errors for a broken tracks block; the `! warn environment:` advisory; `AGENTS.md` step 4; the README section; the repository profile's updated findings.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-024 | info | `README.md`, `.ai/schemas.md`, `AGENTS.md`, `.ai/README.md` | Tracks, the exploring rule, vet, reopen, the lock, and the advisory are documented in every place an operator or agent reads, with the command sequence spelled out and the "fix goes through remediation, reshaping goes through reopen" distinction stated. | `.ai/rules/general.md` (new behavior must be documented) |
| REV-025 | info | `AGENTS.md` step 4 | The bootstrap contract now tells an agent which skill to load while `status` is `exploring`. Because `AGENTS.md`'s interior is installed into governed repositories, agents there get the same instruction after a refresh. | `.ai/rules/general.md` |
| REV-026 | minor | `changes/init-command`, `changes/upstream-failure-reporting` | Two open records in this repository predate `track:`; they read as the default (gated) today. If the default is ever flipped, pin them first (REV-002). Follow-up, not blocking. | `.ai/schemas.md` |
| REV-027 | info | this change record | Running `gate all --change lifecycle-tracks` prints its own advisory block (judgment skipped; accessibility requirements not recorded because specification is skipped). That is the feature working on itself; this change is on the gated track and skips specification with rationale for the last time by default. | `.ai/rules/general.md` |
| REV-028 | info | `README.md` Maturity assessment section (pre-existing) | Still documents `--maturity=scan` although the CLI accepts only `--maturity scan` (open since the accessibility-advisory review, REV-025 there). Unchanged by this change. | Document rules |

## Conformance
Conforms.
