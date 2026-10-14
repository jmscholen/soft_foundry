# Evaluation Results

Commit SHA: 4f3b2dadb445605f059bc1ff942d0de183d35044

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | REQ-PN-009 | pass | evidence/live-panel-transcript.log |
| EVAL-002 | REQ-PN-002, -003, -004, -005 | pass | evidence/live-panel-transcript.log, evidence/live-ARGUMENT.md |
| EVAL-003 | REQ-PN-007 | pass | evidence/live-panel-transcript.log |
| EVAL-004 | REQ-PN-006 | pass | evidence/live-panel-transcript.log |

Fourth run, after remediations REM-001, REM-002, and REM-003 (the runs at d1cf0d6, 2bdc19f, and 2a74680 are superseded); run on 2026-10-08 from 14:44 to 15:04 UTC with the record commit 538b336 checked out, whose code is 4f3b2da, in a scratch repository whose `.gitignore` excludes `.soft-foundry/` as an installed repository's does. Each member wrote its draft in its own temporary folder outside the repository and the runner copied both in; the drafts differed. The members did not agree in round 1 and did in round 2, so this run exercised a second argument round live. Claude Code wrote the specification files citing both drafts; the gate passed (`panel recorded: 2 members, 2 rounds, agreed`); `failures` and `dropped` are empty; the runner's repository-wide comparison found no change outside each stage's allowance; nothing outside the phase folder changed except the change's metadata, which the runner writes.

Across the four runs the panels settled on different designs (VERSION file, constant, VERSION file, VERSION file with corrections), each from the members' own investigation.

## Failures
None.

Observations:
- EVAL-OBS-001: the agreed "sentence" was a full paragraph naming requirement and criterion ranges. Agreement detection still worked because both members copied it exactly; the prompt asks for one sentence but nothing enforces it.
- EVAL-OBS-002: the guard, in warn mode, logged seven shell commands that only read `.ai/` files (for example `cat .ai/README.md`) because a shell command naming a path in a deny-write set is flagged. This predates this change and is noise for every phase, panel or not.
- EVAL-OBS-003: with `GROK_FOLDER_TRUST=0`, Grok ran the project's `.claude/settings.json` hooks (folder trust disabled means ungated), which is how its hook environment was observed.
- Not exercised live: a split, a Codex member (Codex testing is paused), and a four-member panel.

## Accessibility observations
The runner's lines (`panel:`, `running`, `! warn panel:`) carry status words and read the same with non-ASCII bytes deleted; members' own output passes through as each shell prints it.
