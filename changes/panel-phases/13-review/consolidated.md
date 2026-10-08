# Consolidated Review

Reviewed at `a47a2f35ba68fd3cce6b3e703348e65debaf8ffb`. Provider xAI, model grok-4.7, which is not the provider that implemented or remediated (both Anthropic). No application, test, infrastructure, or earlier-phase file was modified.

The first review's majors are closed: REV-FUN-001, REV-FUN-003, REV-SEC-001, REV-SEC-002, REV-SEC-003, and REV-A11Y-001. Regression tests in `test/panel_remediation_test.rb` passed (with `test/panel_phases_test.rb`: 24 runs, 167 assertions, 0 failures). The findings below are what those fixes do not cover, reproduced in a throwaway repository.

## Functional

Conforms on refusals, bounds, resume, agreement detection, forged lines, spoiled argument text, non-zero consensus, missing executables, split parking, and the live two-member panel. REV-FUN-004: a three-member panel whose third member writes nothing completes as a two-member agreement (exit 0), with a warning and a note. REV-FUN-005: drafts written only under `panel/<member>/` are reported as no draft and the panel fails closed. REV-FUN-002: `--shell-arg` still has no RED commit of its own; the feature is accepted.

## Architecture

`Panel`, `CLI`, and `Guard` match the decisions in `05-implementation/decisions.md`. REV-ARCH-001: the change page lists `panel recorded` for every panel phase, and the gate runs it only when a complete handoff has a `panel:` block. REV-ARCH-002: control-plane and README writes are outside the implementation write set; accepted because REQ-PN-001, REQ-PN-005, and REQ-PN-010 require them. The fingerprint is taken after the independent round and rebased after a spoiled argument round, which is the structure behind REV-SEC-005 and REV-SEC-006.

## Security

Does not conform. Three allows, each reproduced with `Guard#decide`, and two of them followed through `panel_run`:

- REV-SEC-004. Independent `Write` to the in-repo own folder is allow, and `Grep` with no path (also `Glob **/*.md`, `Grep` of `changes/<slug>`) is allow. The sibling draft is readable before the argument round. Block mode does not stop either call.
- REV-SEC-005. Argument-stage Bash that hides the draft path in an assignment is allow. The round is spoiled, the replacement becomes the baseline, and round 2 can agree. Reproduced: exit 0, status complete, the cited draft is the replacement, failures empty, a note names the change.
- REV-SEC-006. The same assignment form writes `specification.md` during the independent stage and is allow. The write is the fingerprint baseline. Reproduced: exit 0, no warn, status complete, the injected line still at the start of the file after an in-place consensus edit.

The agree sentence is not copied into the consensus prompt. A draft changed during the consensus fails the run. A malformed member name still disables narrowing (ATK-RES-001); no member input reaches that, so it is not a new finding.

## Accessibility

Conforms with advisories. REV-A11Y-002: the agreed and no-agreement lines have no pass/fail/warn/skip word. Refusals and the split warning do. The skipped specification leaves the expected advisory that no accessibility requirement was recorded.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are all NOT_APPLICABLE. Nothing this change collects, shares, retains, or promises is covered by a published clause. Policy text changes owed: None.

## Infrastructure

N/A. No IaC. `surfaces.infrastructure` is false. CI workflow untouched.

## Operations

No production service. REV-SEC-006 is indistinguishable from a clean agreement: exit 0, no warn, empty failures. REV-SEC-005 and REV-FUN-004 warn and still exit 0.

## Blocking findings

None. The three majors are for judgment. They are not blocking conditions on this handoff.

## Residual concerns

Default guard mode is warn, so violations the tests call denied still run unless a machine sets block. That is existing policy, and it is not one of the findings: those three are allows. A `Process.spawn` failure after both shells have resolved can leave an earlier member running; the missing-executable case is fixed, and this input was not reached. Agreement still does not require the agree line to be one sentence (EVAL-OBS-001); both members copying a longer line is the behavior the equality check specifies.

## Unresolved findings

REV-SEC-004, REV-SEC-005, REV-SEC-006 (major). REV-FUN-004, REV-FUN-005, REV-FUN-002, REV-ARCH-001, REV-ARCH-002, REV-A11Y-002 (minor).
