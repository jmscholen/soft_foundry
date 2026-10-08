# Consolidated Review

## Functional

Conforms with advisories. AC-001 through AC-015 hold in the implementation and in verification, evaluation, and attack evidence at `93acd89` (no application diff since). REV-FUN-001: `soft-foundry session` with any subcommand other than `log` exits 0 and prints nothing. REV-FUN-002: `phase` usage text omits `grok`, which help text and the runner accept.

## Architecture

Conforms with advisories. Ledger, installer, CLI, runner, guard map, and snapshot match the existing layering. No new dependency. RED-then-GREEN was kept, including the remediation. REV-ARCH-001: implementation wrote `.ai/schemas.md`, `.ai/templates/handoff.yml`, and `README.md`, outside its write set. Review accepts that exception because REQ-SL-015 requires those words and no skill can write them. The maintainer still accepts the control-plane edit at merge. The two post-RED test edits are accepted; they do not weaken an expectation.

## Security

Conforms with advisories. Payload validation, quoting of the folder, secret-shape masking, private modes, symlink refusal, the 1 MB cap, the lock, the Grok tool map, and text-only UI rendering match the threat model and the attack results. REV-SEC-001 (major): resume commands trust a session ID already in the ledger and do not quote it, so a same-user writer can make a pasted command run more than the resume. REV-SEC-002 (minor): `SOFT_FOUNDRY_SESSIONS` can name a relative or in-repo path, and record will `chmod` that parent to 0700. TM-001 stands: an unmapped Grok tool name is not guarded.

## Accessibility

Conforms with advisories. CLI status words, stable prefixes, and no color on the new commands. The recorded-sessions block is a real list with a heading, text status, a keyboard link, and a selectable command (WCAG 2.2 1.3.1, 1.4.1, 2.1.1, 2.4.7, 4.1.2; reflow relies on existing `overflow-wrap`). REV-A11Y-001: truncation is marked only with a non-ASCII ellipsis. REV-A11Y-002: `resume` success prints no status word. EVAL-OBS-003 is not a failure; the list item's children carry the name. These are go-live advisories, not a block on the handoff.

## Policy conformance

Conforms. The change newly retains masked prompt excerpts, folders, and branches on the user's machine and sends nothing. No published privacy policy, security policy, or terms exists (`.ai/repository.yml` `policies:` all NOT_APPLICABLE). The privacy rationale and README describe the ledger. Policy text changes required: None. Nothing to park under `human_decisions`.

## Infrastructure

N/A. No Infrastructure as Code in the repository and none in the diff.

## Operations

Conforms. The silent hook is required by REQ-SL-005; `sessions` showing nothing new, plus doctor's install line, is the specified signal. No production dashboard is owed. User-documentation, FAQ index, and observability phases are still pending and optional.

## Blocking findings

None.

## Residual concerns

- REV-SEC-001 should be fixed or accepted in judgment before the paste command is trusted against a ledger the user (or their agent) can edit.
- REV-SEC-002, REV-FUN-001, REV-FUN-002, REV-A11Y-001, REV-A11Y-002, REV-ARCH-001: minor, as above. REV-ARCH-001 is accepted here; the merge is the maintainer's.
- TM-001: an unmapped Grok tool name such as `edit_file` is still not guarded.
- Codex capture, the Codex hook payload, and the runner's Codex session lookup were not run live. Codex's login on this machine could not be refreshed (EVAL-006). Tests cover the documented payload.
- A Grok hook payload carries no transcript path, so status is only "folder missing" or "resumable" (EVAL-OBS-002).
- Masking covers the six `ContentScan::SECRETS` shapes only. The ledger is not pruned. Hook failures after install are silent by specification.
- FIND-ATK-001 (payload over 1 MB is skipped) and FIND-ATK-002 (control characters stripped from a folder name) are documented in README and are not reopened.
