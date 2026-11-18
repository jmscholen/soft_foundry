# Operations Review

## Scope reviewed
What a person operating the tool sees and runs:
- `change status`;
- the `phase run quality` help text;
- `soft-foundry ci` on existing records;
- the upgrade path for repositories already initialized;
- the new-install path, now fixed.

On a new install, `init --maturity scan` in a Ruby repository writes `quality_gate.enabled: true`. This session reproduced it on a scratch repository. A repository that is already initialized and still carries the template's `set_by: null` gets the gate set on its next `onboard --reassess`. A person's `set_by` is never touched. The full-suite runtime is about 21 minutes (VER-003).

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-007 | minor | `.ai/harness-evals/` (not read) | Still open. No harness eval case covers the new `quality findings classed` check (DEV-003). | A later regression is caught only by the unit tests, not by `soft-foundry eval`. | Follow-up |
| REV-008 | minor | local install | Still open. The globally installed `soft-foundry` predates this branch (VER-002). Gate and seal with `ruby -Ilib exe/soft-foundry`, or install the branch first. | A seal with the old binary refuses this record for a reason that is not real. | Operations |

## Conformance
Conforms with minor findings. PC-001 (the maintainer's post-merge check) should now see the phase required at medium risk in a freshly initialized Ruby repository.
