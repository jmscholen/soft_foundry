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
