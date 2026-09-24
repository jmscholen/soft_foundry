# Learning

## What this change taught us
Three lessons, recorded as instincts in `instincts.yml`: sanitise transcripts before they become evidence (the scan flagged this record's own transcript, correctly); exempt closed evidence in policy rather than by editing it (the canary in `init-command`); and reset what a test assumes empty when the fixture copies a real file that grows (`learned.md` after the first promotion).

## Reviewer/evaluator/attack findings worth generalizing
- REV-005 (evaluation harness): the alternative to sanitising, exempting our own evidence, would have taught the first user the wrong thing.
- REV-020 (operations): closed records' evidence is scanned only on demand; a `scan` step in `ci` closes that.

## Proposed deterministic checks
- `scan` in `ci` over closed records' evidence (REV-020).
- A `Finding#to_s` used by both `check` and `scan` (REV-008), and the marker hint said once per run (REV-014).

## Proposed rule changes
See `proposed-rules.md`. The two instincts at or above 0.80 are proposals for the next promotion.

## Proposed harness evals
See `proposed-evals.md`.
