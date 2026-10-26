# Consolidated Review

Reviewed at `c3a971eb6dfd494b48cc06a48ca235205d654eae` on provider xAI (Grok 4.7). Implementation and remediation ran on Anthropic. Rules loaded: the implementation baseline (`general`, `architecture`, `security`, `errors`, `dependencies`, `observability`, `git`, `learned`) and the discovered Ruby and testing rules, plus `accessibility`, `policy-conformance`, and `infrastructure`.

## Functional

Does not fully conform. REV-001 (major): a kill between the metadata rename and the handoff renames leaves a reopen history entry while the handoffs stay complete, so close can succeed. REV-002 (major): `discharged_at: ""` is discharged in the CLI and open in the UI. REV-003, REV-005, and REV-006 are minor. Deviations D2, D4, D5, and D8 are accepted. Detail in `functional.md`.

## Architecture

Conforms with REV-001. D2 is approved: `downstream` follows lifecycle order and `next` edges only, which is what makes AC-001 and AC-002 both true. Detail in `architecture.md`.

## Security

Conforms with REV-002. Marker refusal, guard parsing, `--env` redaction, free-text rejection of invisible characters, and the release and reopen lock hold. Accepted residuals: unsetting `SOFT_FOUNDRY_PHASE` (TB-1), the `--env` process-title window and shell history (D6), look-alike characters in displayed text, and adopter-owned resource isolation. Detail in `security.md`.

## Accessibility

Conforms with advisories. REV-002 cites WCAG 1.3.1. CLI outcome words, prefixes, table headers, state words, and header contrast (6.03:1 light, 7.12:1 dark) hold. The rendered page was not operated with a keyboard or a screen reader. Detail in `accessibility.md`.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are `NOT_APPLICABLE` and publish no document. Nothing in the diff changes what is collected, shared, retained, protected, or promised about a person. Policy text changes owed: None. Detail in `policy-conformance.md`.

## Infrastructure

N/A. No Infrastructure as Code is present or modified. `.ai/rules/infrastructure.md` was loaded and has nothing in this diff to judge. Detail in `infrastructure.md`.

## Operations

Conforms with REV-004, REV-005, and REV-007. The timeline records reopens, releases, and discharges. `docs/user/` and the harness-eval cases named by REQ-027 were not added. Plain `change status` omits reopenings. `ps` shows only the first phase of a parallel run. Detail in `operations.md`.

## Blocking findings

None. REV-001 and REV-002 are major and should be settled before an approving judgment. They are findings, not a blocked review: the phase completed and names the input and the wrong result for each.

## Residual concerns

- D3 / REV-003: the gate exits 0 on a reopened phase. Close still refuses. The specification owner can amend AC-014 or the gate can grow a distinct result. This review does not ask for the pending gate to start failing.
- D6: `--env` values remain in shell history and in `ps` until `setproctitle` runs.
- TB-1: a session that unsets `SOFT_FOUNDRY_PHASE` can release or reopen.
- ATK-002: visible look-alike characters are stored and shown.
- ATTACK-011 was not run (symlink and held-lock cases).
- REV-006: a rerun keeps the previous `started_at`.
