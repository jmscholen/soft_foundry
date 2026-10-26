# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| release-block-malformed | `check` refuses a released record whose item has a blank or non-string `discharged_at` | REV-002 | gate/check names the item and exits non-zero |
| parallel-not-isolated | `phase run A B --parallel` with a phase outside `isolated_phases` is refused before any session starts | REQ-027, JUDGE-004 | exit non-zero, no handoff touched |
| stale-auto-reopen | `phase run` on a complete but stale phase reopens it, records `phase_reopenings`, then runs | REQ-027, JUDGE-004 | history entry present and phase reruns |
| reopen-kill-between-renames | a kill during `phase reopen` never lets `change close` succeed | REV-001, REV-008 | close refuses for every kill point |
| discharged-agreement | CLI and page agree on open item count for `""`, whitespace, and U+00A0 `discharged_at` | REV-009 | counts equal on both surfaces (currently fails for U+00A0) |
