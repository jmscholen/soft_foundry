# Threat Model

## Trust boundaries
See trust-boundaries.md. The new boundary is person-to-record: this change makes a person's recorded decision the only way past the remediation cap and the specify seal.

## Externally controlled inputs
metadata.yml (human_decisions, status, rules version, run_phases, phase_reopenings), acceptance-criteria.yml (tier, person_checks), 14-judgment/evidence.yml (blocked_by), review and attack handoff findings (outside_change, follow_up, paths), `phase reopen` options (--docs-only, --reason), and the git history of the record's branch. All are written by sessions or committers and read by the gate as data.

## Authorization boundaries
Only a person records human_decisions. Phase-run sessions may not reopen. The gate never accepts a flag or option in place of a decision (REQ-017).

## Abuse cases
THREAT-001 to THREAT-008 in threats.yml: a fabricated decision, a reset round count, leaving awaiting_human by hand, code under a docs-only reopen, demoting an approved must, an in-change finding marked outside_change, a new record made to look legacy, and a misdeclared risk or diff to get waivers and small sizes.

## Injection / XSS / CSRF / SSRF / file risks
N/A for XSS, CSRF and SSRF: no web surface or outbound request is added. Injection: reasons and notes are free text already validated by `Text.free_text!`; new free-text fields (follow_up, decision note) use the same validation and are printed through `Display.safe`. File: no new file is read outside the record; paths in outside_change findings are compared as strings with the diff, never opened.

## Resource exhaustion and DoS
THREAT-010: round counting is one bounded git query per gate run.

## Infrastructure exposure
None. No deployed service.

## Proposed attack cases
- ATK-P1 (THREAT-001): shell-write a must criteria approval into metadata.yml from an open session and seal specify; expect the seal note to name human_decisions as hand-edited.
- ATK-P2 (THREAT-002): delete remediate entries from phase_reopenings after two sealed rounds and reopen; expect refusal from the commit count.
- ATK-P3 (THREAT-002): reach a third remediation without a reopen (reopen verify, seal remediate from pending); expect the remediate seal to refuse.
- ATK-P4 (THREAT-003): set status in_progress by hand after parking, run review and judge gates; expect both to fail on the cap.
- ATK-P5 (THREAT-004): docs-only reopen, commit lib/ and .ai/ changes, seal remediate; expect refusal; then commit lib/ after a docs-only seal and gate verify; expect stale.
- ATK-P6 (THREAT-005): change a must to should after the specify seal and update the approval entry to match; expect the lock to fail.
- ATK-P7 (THREAT-006): mark a finding about a path in the diff outside_change; expect the review gate to fail.
- ATK-P8 (THREAT-007): delete the rules version after the intake seal; expect the first-phase gate to fail.
- ATK-P9 (THREAT-008): a diff of README.md plus one lib/ file; expect the larger size.
