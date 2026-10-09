# Consolidated Review

Fourth review of panel mode, at `661b454`, after REM-003 (`4f3b2da`). The panel code is that commit. The third review's synchronous failures were re-run and are closed. Five majors are new. None are blocking. Judgment decides whether they are residual risk or a return to remediation.

## Functional

Does not conform. Membership, bounds, agreement-from-appended-text, clean-split parking, the gate check, the dry run, and version `0.20.0` hold. REQ-PN-002 does not hold when one member reads the other's temp draft and changes one byte (REV-SEC-011). The runner snapshot does not hold for a detached write after agreement (REV-SEC-012), a `.git` hook (REV-SEC-013), a gitignored guard override (REV-SEC-014), or a retry after a caught write (REV-SEC-015). Minors: paragraph-length `agree:` lines (REV-FUN-007), deleting `ARGUMENT.md` crashes instead of a panel failure (REV-FUN-008), consensus failures keep outcome `agreed` or `split` (REV-FUN-009), `--shell-arg` has no RED commit of its own (REV-FUN-002).

## Architecture

Conforms, with two minors. `panel recorded` is listed for every panel phase and run only when a complete handoff has the block (REV-ARCH-001). Control-plane and README edits sit outside the implementation write set because the requirements demand them (REV-ARCH-002, accepted). The snapshot belongs in `Panel`; the holes are the security findings, not a second design.

## Security

Does not conform. Closed, reproduced this review: REV-SEC-007 (handoff), REV-SEC-008 (synchronous `lib/app.rb`), REV-SEC-009 (byte-identical drafts), REV-SEC-010 (dotfile), REV-FUN-006 (failed split is not parked). Open: REV-SEC-011 through REV-SEC-015, plus minor REV-SEC-016 (a caught handoff plant is merged, so the blocked file still carries the attacker's `findings`). THREAT-001 stays the prompt mitigation the attack phase could not prove against a live model. A malformed panel-member env still skips narrowing (ATK-RES-001); the runner sets that env.

## Accessibility

Conforms with advisories. Outcome lines for agree, split, refuse, and snapshot failure use `pass`, `warn`, or `fail`. REV-FUN-008's `soft-foundry: No such file or directory` line does not, and it does not say what to do next. No web UI. The skipped specification leaves the existing go-live advisory that no accessibility requirement was recorded.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are all NOT_APPLICABLE. A panel stores session ids and drafts in the change record the person commits; single-session `phase run` already stored the session id. No new recipient and no published clause to change. Policy text changes owed: none. No `human_decisions` entry is required.

## Infrastructure

N/A. No IaC in the diff. `surfaces.infrastructure` is false. `infrastructure.iac.tools` is empty.

## Operations

Does not conform for the detector REM-003 describes. There is no deployed service and the pending observability phase matches `surfaces.observability: false`. The CLI success lines fire for REV-SEC-012, REV-SEC-013, and REV-SEC-014. REV-SEC-015's retry prints success over planted bytes.

## Blocking findings

None. Majors are for judgment, not a withheld review.

## Residual concerns

- REV-SEC-011 is the residual REM-003 asked judgment to accept (no OS sandbox; only identical drafts fail). It was reproduced, including listing `soft-foundry-panel-*` in the system temp directory before any draft file exists. This review does not call it closed.
- REV-SEC-012..015 are not that residual. They are holes in the repository snapshot that REM-003 presents as the authority: timing, `.git` and gitignored paths, and a dirty baseline after a detected write.
- REV-FUN-007, REV-FUN-008, REV-FUN-009, REV-FUN-002, REV-ARCH-001, REV-ARCH-002, REV-SEC-016.
- Inter-agent instruction injection (ATTACK-001) and a malformed member name (ATK-RES-001), as the attack record left them.
