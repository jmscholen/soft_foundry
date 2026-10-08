# Consolidated Review

Reviewed at `11c69d2045fe1d1db2e3118b7e3f17f401b95169` (panel behavior `2a74680`). Provider xAI, model grok-4.7, which is not the provider that implemented or remediated (both Anthropic). No application, test, infrastructure, or earlier-phase file was modified.

Closed on the inputs they named: REV-FUN-001, REV-FUN-003, REV-FUN-004, REV-FUN-005, REV-SEC-001, REV-SEC-002, REV-SEC-003, REV-SEC-004, REV-SEC-005, REV-SEC-006, REV-A11Y-001, and REV-A11Y-002. `ruby -Ilib:test test/panel_remediation_test.rb` passed (29 runs, 185 assertions, 0 failures), including the original panel tests. The findings below are what those fixes do not cover, reproduced with `Guard#decide` and `panel_run` in a throwaway repository.

## Functional

The requirement paths the tests and the live panel exercise hold, including refusals, bounds, resume, agreement detection, forged lines, spoiled argument text, non-zero consensus, missing executables, intact split parking, and `dropped`. REV-FUN-006: a split whose consensus also replaces a draft is parked at `awaiting_human` even though the run fails and the README says a failed panel is not parked. REV-FUN-002: `--shell-arg` still has no RED commit of its own; the feature is accepted.

## Architecture

`Panel`, `CLI`, and `Guard` match the decisions in `05-implementation/decisions.md`. REV-ARCH-001: the change page lists `panel recorded` for every panel phase, and the gate runs it only when a complete handoff has a `panel:` block. REV-ARCH-002: control-plane and README writes are outside the implementation write set; accepted because REQ-PN-001, REQ-PN-005, and REQ-PN-010 require them. Fingerprints skip `handoff.yml`, the argument output fingerprint skips dotfiles, and shell narrowing ignores paths outside the phase directory. That structure is REV-SEC-007, REV-SEC-008, and REV-SEC-010.

## Security

Does not conform. Three allows, each followed through `panel_run` to exit 0, outcome `agreed`, empty failures, and a passing `panel recorded` check:

- REV-SEC-007. Bash that hides `handoff.yml` in an assignment is allow in the independent and argument stages. The literal redirect is a violation. A grok-1 write of `findings` id PLANTED and `notes` planted-note during round 1 survives a consensus that only merges status, commit_sha, and completed_at.
- REV-SEC-008. A literal redirect of `00-intake/request.md` is allow in every stage, and a literal redirect of `metadata.yml` is allow. An assignment that writes `lib/app.rb` is allow; the literal redirect of that path is a violation. Each followed-through write is still in the file after an agreed panel.
- REV-SEC-009. Both staging directories are created under the shared temp directory before either member runs. A shell scan that does not contain `soft-foundry-panel-` is allow. grok-1 listing that directory and copying claude-1's draft leaves `panel/grok-1/draft.md` byte-identical to claude-1's, including the sentence `Only claude wrote this sentence.`

REV-SEC-010 (minor): an argument-stage dotfile in the phase folder is not fingerprinted; the same file during the independent stage fails the run. A malformed member name still disables narrowing (ATK-RES-001); no member input reaches that, so it is not a new finding.

## Accessibility

Conforms. REV-A11Y-002 is closed: agreement, no agreement, split, dropped member, refusal, and failure lines carry `pass`, `warn`, or `fail` after the glyph is stripped. Informational lines use the `panel:` prefix. The skipped specification leaves the expected advisory that no accessibility requirement was recorded.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are all NOT_APPLICABLE. Nothing this change collects, shares, retains, or promises is covered by a published clause. Policy text changes owed: None.

## Infrastructure

N/A. No IaC. `surfaces.infrastructure` is false. CI workflow untouched.

## Operations

No production service. REV-SEC-007, REV-SEC-008, and REV-SEC-009 are indistinguishable from a clean agreement: exit 0, no warn, empty failures, gate pass. REV-FUN-006 fails the command and also parks the change.

## Blocking findings

None. The three majors are for judgment. They are not blocking conditions on this handoff.

## Residual concerns

Default guard mode is warn, so a violation still runs unless a machine sets block. That is existing policy, and it is not one of the majors: those three are allows. A `Process.spawn` failure after both shells have resolved can leave an earlier member running; the missing-executable case is fixed, and this input was not reached. Agreement still does not require the agree line to be one sentence (EVAL-OBS-001); both members copying a longer line is the behavior the equality check specifies. Inter-agent prompt injection is mitigated by the prompts and the guard, not prevented (ATTACK-001, not run live).

## Unresolved findings

REV-SEC-007, REV-SEC-008, REV-SEC-009 (major). REV-SEC-010, REV-FUN-006, REV-FUN-002, REV-ARCH-001, REV-ARCH-002 (minor).
