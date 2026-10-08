# Operations Review

## Scope reviewed

How an operator tells that a panel succeeded, failed, split, or was tampered with. `surfaces.observability` is false. `12-observability/` is still the pending template, which is correct for a library with no production service: `.ai/repository.yml` marks failure detection, health, operational visibility, and alerting NOT_APPLICABLE. Rules: `.ai/rules/observability.md`, `.ai/rules/errors.md`. Compared with `CLI#panel_run` and the live transcript.

## Findings

No separate operations finding. The detection gaps are the security findings:

- REV-SEC-006 exits 0 with no warn line and an empty `panel.failures`. Nothing in the handoff says the phase file was written during the independent round. There is no log, metric, or alarm to add for a local CLI; the missing signal is the exit code and the fail line the other panel failures already use.
- REV-SEC-005 does emit `! warn panel:` and a `panel.notes` entry, then still exits 0 with status `complete`. An operator who reads the note can see the replaced draft. An operator who trusts the exit code and `outcome: agreed` cannot.
- REV-FUN-004 emits the same warn and note, then exits 0. The dropped member is absent from `panel.members`.

Split, consensus crash, fewer than two staged drafts, and a draft changed during the consensus all exit non-zero, print `✗ fail panel:` or `! warn panel:`, and leave `blocking` set. That is the detection path this CLI has, and it is the one those cases use.

## Conformance

The production observability standard is not applicable. The CLI's own failure reporting conforms for the cases the remediation tests cover, and does not conform for REV-SEC-006, which is indistinguishable from a clean agreement.
