# Consolidated Review

Reviewed at `2be4aff7a95b8a9b17e745d9d07171affce92bfc` on provider xAI (Grok 4.7). Implementation (`d2050f6`) and remediation (`030b28f`) ran on Anthropic. Rules loaded: the implementation baseline (`general`, `architecture`, `security`, `errors`, `dependencies`, `observability`, `git`, `learned`) and the discovered Ruby and testing rules, plus `accessibility`, `policy-conformance`, and `infrastructure`. `lib/` and `test/` are unchanged since `030b28f`.

## Functional

Conforms with minor findings. The previous REV-001 and REV-002 do not reproduce: handoffs are renamed before metadata, and an ASCII-blank `discharged_at` is open in the CLI and the page and is refused by `Release.lint`. REV-008 (minor): a kill or a raised error between those renames leaves pending handoffs, no history entry, and a leftover temp file. Close still refuses. REV-009 (minor): a hand-edited `discharged_at` of only U+00A0 is discharged in Ruby and open in the page. REV-003, REV-005, and REV-006 are minor. Deviations D2, D3, D4, D5, D6, and D8 are accepted. Detail in `functional.md`.

## Architecture

Conforms with REV-008. D2 is approved: `downstream` follows lifecycle order and `next` edges only, which is what makes AC-001 and AC-002 both true. Detail in `architecture.md`.

## Security

Conforms with REV-009. Marker refusal, guard parsing, `--env` redaction, free-text rejection of invisible characters, and the release and reopen lock hold. The release/reopen race was not reproduced at `89b4011` (14 of 14 pairs, one winner). Accepted residuals: unsetting `SOFT_FOUNDRY_PHASE` (TB-1), the `--env` process-title window and shell history (D6), look-alike characters in displayed text, a hand-edited non-blank discharge timestamp (TB-3), and adopter-owned resource isolation. Detail in `security.md`.

## Accessibility

Conforms with advisories. REV-009 cites WCAG 1.3.1. CLI outcome words, prefixes, table headers, state words for values the discharge command writes, and header contrast (6.03:1 light, 7.12:1 dark) hold. The rendered page was not operated with a keyboard or a screen reader. Detail in `accessibility.md`.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are `NOT_APPLICABLE` and publish no document. Nothing in the diff changes what is collected, shared, retained, protected, or promised about a person. Policy text changes owed: None. Detail in `policy-conformance.md`.

## Infrastructure

N/A. No Infrastructure as Code is present or modified. `.ai/rules/infrastructure.md` was loaded and has nothing in this diff to judge. Detail in `infrastructure.md`.

## Operations

Conforms with REV-004, REV-005, REV-007, and REV-008. The timeline records completed reopens, releases, and discharges. `docs/user/` and the harness-eval cases named by REQ-027 were not added. Plain `change status` omits reopenings. `ps` shows only the first phase of a parallel run. A killed reopen names the leftover temp file and does not record the reason once every handoff is already pending. Detail in `operations.md`.

## Blocking findings

None. The two majors from the review at `2da13ad` are fixed in `030b28f` and were re-checked in this tree and in the attack at `89b4011`. The findings above are minor. They name a concrete input and a wrong result in the review files. They are not a reason to withhold this handoff.

## Residual concerns

- REV-008 / AC-017: rename is per file. The safe order is in place. All-or-nothing across the handoffs and the history entry is not. The specification owner can amend AC-017, or a later change can add a journal. This review does not ask for another remediation cycle on a fail-closed crash window.
- REV-009: one blank test shared by Ruby and the page would close the U+00A0 split. The discharge command cannot write that value.
- D3 / REV-003: the gate exits 0 on a reopened phase. Close still refuses. This review does not ask for the pending gate to start failing.
- D6: `--env` values remain in shell history and in `ps` until `setproctitle` runs.
- TB-1: a session that unsets `SOFT_FOUNDRY_PHASE` can release or reopen.
- ATK-002: visible look-alike characters are stored and shown.
- ATTACK-011 was not run (symlink and held-lock cases). Kill-mid-write was run for phase reopen only.
- REV-006: a rerun keeps the previous `started_at`.
- Verification's suite (786 runs, 0 failures) was not re-run here. It measures `030b28f`, which is still the code.
