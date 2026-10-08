# Consolidated Review

Commit reviewed: `726edc107151e91e708ea8ba4ce367ee516bf19f`. No application, test, infrastructure, or earlier-phase file was modified.

## Functional

The happy path matches REQ-PN-001..010: bounds and refusals, per-member drafts, agreement from appended text only, a spoiled round, consensus by the first member, the `panel:` block, a real split parked for a person, `--shell-arg`, the dry run's session cap, and the single-provider advisory. Tests and the live claude/grok panel support that.

REV-FUN-001 (major): member process results are discarded. Reproduced: a non-zero consensus exit after agreement makes the command exit 0 with the handoff still `pending` and `executed_by.exit_status` 0, so the gate skips. Members that exit non-zero without writing are parked as a panel split with `exit_status` 0. A missing later executable leaves any member already spawned running.

REV-FUN-002 (minor): `--shell-arg` is accepted; its test has no RED commit of its own. REV-FUN-003 (minor): dry run prints only the independent-round commands.

## Architecture

`Panel`, `CLI`, and `Guard` match the existing runner split. Control-plane and README writes (REV-ARCH-002, minor) are an accepted exception required by the intake. REV-ARCH-001 (minor): `Gate.checks_for` lists `panel recorded` for every panel phase, but the gate runs it only when a complete handoff has a `panel:` block.

## Security

Does not conform in block mode, reproduced with `Guard` on a specify-phase fixture.

- REV-SEC-001 (major): a shell command can write the phase's files during the independent stage, and can replace another member's draft during the argument stage. Write narrowing covers only Edit/Write/`apply_patch`.
- REV-SEC-002 (major): Claude Code `Grep` reads another member's draft during the independent stage. The tool is unguarded, so narrowing sees no path.
- REV-SEC-003 (major): the consensus stage is not narrowed, so the writer can replace the drafts the gate cites, and the agree sentence is interpolated into the consensus instructions.

Bounds, generated member names, forged `agree:` lines, rewritten argument text, and the implement refusal hold. ATK-RES-001 (a malformed member name skips narrowing rather than failing closed) is unchanged and still minor: the runner does not emit such a name, and the skill's own permissions still apply.

## Accessibility

Conforms with advisories. REV-A11Y-001 (minor): refusals have no `fail` word and no `panel:` prefix. No UI. New output lines do not use color or a glyph as the only signal. The specification phase was skipped, so the go-live advisory that no accessibility requirement was recorded is expected; intake only says every new output line carries a status word.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms in `.ai/repository.yml` are NOT_APPLICABLE. The panel's session ids are the same local handoff values `phase run` already records. No policy text change is owed.

## Infrastructure

N/A. No infrastructure-as-code in the change.

## Operations

No production service, so dashboard and alarm rules do not apply. REV-FUN-001 is the detection gap for the new CLI failure mode. `12-observability/` is still pending; nothing in this change requires it.

## Blocking findings

None. The majors are for judgment. They are not a reason to withhold this handoff, and they are not accessibility or policy advisories.

## Residual concerns

- ATK-RES-001 stands: a malformed `SOFT_FOUNDRY_PANEL_MEMBER` disables narrowing instead of failing closed. A member does not control the environment its hooks receive.
- ATTACK-001 was not run live. REV-SEC-003 covers the runner copying the agree sentence into the instruction prompt. A model obeying a draft it was told is data, on a tool the guard does narrow, is still the accepted residual.
- EVAL-OBS-001: the agree "sentence" is not held to one sentence. The live panel agreed on a paragraph because both members copied it. Detection compares normalized text. Not refiled.
- EVAL-OBS-002: the guard warns on shell reads of deny-write paths. Pre-existing. Not this change.
- Verification, evaluation, and attack were done by the session that implemented the change (anthropic), and their handoffs have no `executed_by`. The gate already advises that. This review ran as a fresh grok session.
- `--shell-arg` and the control-plane writes are accepted deviations, with REV-FUN-002 and REV-ARCH-002 recording the limits.
- User-documentation, FAQ index, and observability phases are still pending templates. README, help text, schemas, and the human-boundaries entry already cover REQ-PN-010. That is not a defect in the code reviewed here.

## Unresolved findings carried forward

| ID | Severity | From | Disposition |
| --- | --- | --- | --- |
| REV-FUN-001 | major | this review | Open. Member results ignored. |
| REV-SEC-001 | major | this review | Open. Shell writes escape narrowing. |
| REV-SEC-002 | major | this review | Open. Unguarded tools escape read narrowing. |
| REV-SEC-003 | major | this review | Open. Consensus can rewrite drafts; agree text enters the prompt. |
| REV-FUN-002 | minor | this review | Open process gap. Feature accepted. |
| REV-FUN-003 | minor | this review | Open. Dry run omits later commands. |
| REV-ARCH-001 | minor | this review | Open. `checks_for` over-claims `panel recorded`. |
| REV-ARCH-002 | minor | this review | Accepted exception. |
| REV-A11Y-001 | minor | this review | Open advisory. |
| ATK-RES-001 | minor | `08-attack` | Still open. Not upgraded. |
| EVAL-OBS-001 | minor | `07-evaluation` | Accepted. Not a wrong agreement. |
| EVAL-OBS-002 | minor | `07-evaluation` | Pre-existing. Not this change. |
