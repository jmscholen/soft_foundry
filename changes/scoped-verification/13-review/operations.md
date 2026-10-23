# Operations Review

## Scope reviewed

REQ-018, REQ-020, and REQ-025. `.ai/rules/observability.md` and `.ai/rules/errors.md`. `surfaces.observability` is false (library CLI, no production service). Advisories in `advisory.rb` `scope_notices`, status and gate output, and the pending optional phases `10-user-documentation`, `11-faq-index`, and `12-observability`.

What holds: a scoped diff that leaves the scope, touches shared core with no full-suite block, or matches no changed file prints an `advisory:` / `! warn scope:` line and does not fail the gate (REQ-018, AC-017, EVAL-010). Status prints the declared scope. Stale and size output name the applied scope and a reason per path (REQ-020). Scoped git failures name the cause and the next step. Exit status is non-zero when the gate fails. No new background job, credential, or external dependency.

## Findings

| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-001 | blocking | `Scope.tip_for`; advisory measured from the same tip | The operational signal uses the same branch tip as staleness. Under REV-001 the gate says current, and the empty-scope advisory can fire, while the code that changed is on the checked-out branch. | The ATTACK-019 setup in `transcript3.txt`: `evidence current` passes, and the advisory says the declared scope matches no changed file, after `lib/a/x.rb` was committed on the checked-out branch. An operator reruns nothing. | REQ-018, REQ-020. `.ai/rules/observability.md` (a new failure mode needs a detection path). |
| REV-004 | minor | CLI rescue around `Gate#evaluate` | The scalar-`git` failure is a one-line `TypeError` message with no field name and no next step, so an operator cannot tell it from an internal fault. | `git: "x"` in `metadata.yml`. Exit 1, message `String does not have #dig method` (`transcript3.txt`, ATTACK-018). | `.ai/rules/errors.md`. |

## Conformance

Does not conform, because of REV-001: the status and advisory text describe the frozen branch, so the failure mode this change added is invisible on the checked-out branch. The three REQ-018 advisories themselves print and stay non-blocking when the measure is the real branch. `12-observability` is still pending; the surface is false and there is no service to dashboard. `10-user-documentation` and `11-faq-index` are pending too; the operator text that exists is the README section added in `73298e6` (see REV-005).
