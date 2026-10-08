# Remediation

## Finding references
REM-001, from the first review (fresh Grok session, 13-review at bb24e21):
- **REV-FUN-001 (major).** Member exit statuses were discarded: a consensus that crashed still exited 0 with the phase pending; members that wrote nothing were treated as a split and parked the change; a missing later shell was found only after an earlier member had started.
- **REV-SEC-001 (major).** Shell commands escaped stage narrowing (an independent member could write the phase's files; an arguing member could overwrite another's draft).
- **REV-SEC-002 (major).** Tools the guard does not know (Grep, Glob, Grok's grep) could read another member's draft in the independent stage.
- **REV-SEC-003 (major).** The consensus stage was not narrowed (the writer could replace the drafts the gate cites), and the agreed sentence was placed in the consensus instructions.
- Minors folded in: REV-FUN-003 (the dry run now prints argument and consensus commands), REV-A11Y-001 (panel refusals and failures start with `✗ fail panel:`).

## Root cause
The first design trusted the members' sessions to stay in their lanes, enforced only for named file tools, and kept independent drafts where every tool could search them. It also treated the runner's own bookkeeping (exit statuses, file integrity) as the agents' responsibility.

## Changes made
- RED `2ca6ff2` (11 tests in `test/panel_remediation_test.rb`; reopened 06, 07, 08, 13). GREEN `a525182`:
  - Independent drafts are written to a fresh temporary folder per member outside the repository (`SOFT_FOUNDRY_PANEL_DRAFT_DIR`, prefix `soft-foundry-panel-`), copied into `panel/<member>/` after the round, and the staging folders removed. With fewer than two drafts the panel fails (`outcome: failed`), it does not split.
  - Exit statuses count: a non-zero consensus fails the command and is recorded in `executed_by.exit_status`; failures put the handoff at `blocked` with `panel failed:` lines.
  - The runner fingerprints drafts and the phase's own files: a change during an argument round spoils the round; a change to the drafts or `ARGUMENT.md` during the consensus fails the run.
  - The guard narrows shell commands and any tool whose input names a path, in every stage; the consensus stage may not write the panel folder; every shell is found before any member starts.
  - The consensus prompt points at the last `agree:` line in `ARGUMENT.md` as data instead of quoting it.
- RED `f638ea4` and GREEN `652b19a`: Claude Code members receive `--add-dir <draft folder>`, since Claude Code edits only inside its working folder otherwise (found while preparing the live rerun).
- `2bdc19f`: a regex escape in an existing test, corrected.
- Test corrections after RED: `ls lib` replaced by an allowed path in the shell test (the specification skill already denies `lib/`), and a wait added to the preflight test so a wrongly started member is observed.

## Evidence invalidated
Verification, evaluation, attack, and review at d1cf0d6 / 726edc1.

## Required reruns
Verification, evaluation (the live panel again), attack (with shell, unknown-tool, and consensus cases), and review in a fresh session.

## REM-002 (from the second review)
- **Findings.** REV-SEC-004 (major): an independent member could write its draft inside the repository, where another member's repository-wide search (Grep with no path, Glob `**/*.md`) would find it. REV-SEC-005 (major): a shell command that hides a path in a variable (`f=…/grok-1/draft.md; printf x > "$f"`) replaced another member's draft during the argument; the round was spoiled but a later round could still agree over the replacement. REV-SEC-006 (major): the same trick wrote a phase output during the independent stage, which became the baseline the runner later compared against. Minors folded in: REV-FUN-004 (a dropped member is now recorded as `dropped`), REV-A11Y-002 (the agreed and no-agreement lines carry `pass` and `warn`).
- **Root cause.** The first remediation still treated the guard's shell parsing as a boundary; a shell can always hide a path. The runner's own fingerprints are the authority, and they started too late (after the independent round) and treated draft changes during the argument as recoverable.
- **Changes.** RED `f69d6f2` (five tests; reopened 06, 07, 08, 13). GREEN `2a74680`: the runner fingerprints the whole phase folder before the independent round and fails the run on any change during it; a changed draft or phase output during the argument fails the run immediately (no consensus); the guard allows no in-repository write in the independent stage (drafts go to the outside folder only); the panel block records `dropped`; outcome lines carry status words. The older guard test that allowed an in-repository own-folder write in the independent stage was changed to expect a refusal (REM-002 changes that rule).
- **Evidence invalidated.** Verification, evaluation, attack, and review at 2bdc19f. All rerun at 2a74680.
