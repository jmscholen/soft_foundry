# Implementation Log

## Changes made
- `lib/soft_foundry/maturity_report.rb` (new): `MaturityReport` renders `.ai/repository.yml`'s already-recorded capability findings into `summary_lines` (short, for the terminal) and `to_markdown` (full, for a persisted file). Distinguishes capabilities blocking the next level (`maturity.gaps`) from other non-satisfied capabilities recorded but not yet blocking. Pure presentation; no assessment logic.
- `lib/soft_foundry/onboarding.rb`: `assess_maturity`'s three branches (scan, deep, already-assessed-skip) all now call a shared `print_maturity_report`, which writes `.ai/maturity-report.md` via `SafeWrite` and prints the summary. Critically, the skip branch calls it too — the case that motivated this change, since a repository already assessed would otherwise keep showing nothing forever.
- `README.md` documents the report.

## Decisions
| Decision | Reason |
| --- | --- |
| Report regeneration is idempotent (skip the write when content is unchanged) | Matches this tool's existing guarantee that a repeated `init` run leaves no diff; a report rewritten every run with identical content would churn its mtime and dirty `git status` for no reason. |
| Comparison uses `.b` (binary) on both sides before `==` | Found via a real repro, not by inspection: `File.binread` returns `ASCII-8BIT`, the rendered markdown is `UTF-8`; Ruby's `String#==` compared them unequal despite byte-identical content, which defeated the idempotency check entirely. `.b` normalizes both sides to a byte-exact comparison regardless of source encoding. |
| Other deficiencies get a count in the terminal, full detail only in the file | Keeps the terminal output terse and actionable (matches `scan` mode's existing brevity) while the file carries the complete rationale/findings/evidence for each one. |

## Deviations from plan
None. No separate planning phase ran for this change (see `00-intake/assumptions.md`).

## Challenges
One real bug, found only by writing an in-process repro after a subprocess-level repro showed content was byte-identical yet the file's mtime still changed on every run: the ASCII-8BIT/UTF-8 comparison gap described above. Fixed with `.b` on both sides and covered by a regression test asserting a report file's mtime is unchanged across two successive `init` runs.
