# Operations Review

## Scope reviewed

How an operator tells that a panel succeeded, failed, split, or was tampered with. `surfaces.observability` is false. `12-observability/` is still the pending template, which is correct for a library with no production service: `.ai/repository.yml` marks failure detection, health, operational visibility, and alerting NOT_APPLICABLE. Rules: `.ai/rules/observability.md`, `.ai/rules/errors.md`. Compared with `CLI#panel_run`, `Panel#run`, and the live transcript.

## Findings

No separate operations finding. The detection gaps are the security findings:

- REV-SEC-007, REV-SEC-008, and REV-SEC-009 exit 0 with no warn line and an empty `panel.failures`. The gate prints `panel recorded` pass. Nothing in the handoff says a member wrote the handoff during the argument, replaced an earlier file, or copied another draft. There is no log, metric, or alarm to add for a local CLI; the missing signal is the exit code and the fail line the other panel failures already use.
- REV-SEC-010 leaves a dotfile and also exits 0. The cited outputs are unchanged, so an operator looking only at those files does not see it.
- REV-FUN-006 does emit `✗ fail panel:` and exits 1, and also emits the split park warning. An operator who trusts `awaiting_human` alone treats a tampered split as a decision for a person.

Split with intact drafts, consensus crash, fewer than two staged drafts, an independent change to a watched phase file, and a draft changed during the argument all exit non-zero, print `✗ fail panel:` or `! warn panel:`, and leave `blocking` set. That is the detection path this CLI has, and it is the one those cases use.

## Conformance

The production observability standard is not applicable. The CLI's own failure reporting conforms for the cases the remediation tests cover, and does not conform for REV-SEC-007, REV-SEC-008, and REV-SEC-009, which are indistinguishable from a clean agreement.
