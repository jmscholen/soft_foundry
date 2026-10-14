# Change Intake

## User intent
Change 3 of the shared plan ("Soft Foundry: Agent-Workflow Additions Plan"), built in order; the maintainer merged changes 1 and 2 and the plan continues. From the article: for a hard bug the author runs two GPT and two Claude agents, each investigates alone into its own folder, then they "communicate with each other through a blank ARGUMENT.md file" until they agree; one writes a short root-cause README that he reads before anything is implemented. The "slow lane" version has two agents each write an exhaustive spec and argue to one final spec. The plan's recommendation, which stands because the decision dropdown was left empty: a panel of two by default, four on request.

## Desired outcome
Stable requirement IDs, since the specification phase is skipped for this change (see `metadata.yml`):

- **REQ-PN-001 (start).** `soft-foundry phase run <phase> --panel SHELL,SHELL[,...] [--max-rounds N] [--dry-run]` runs the phase as a panel of two to four members named `<shell>-<n>` (`claude-1`, `grok-1`, `claude-2`). Panels are allowed only for the phases listed under `panel_phases:` in `.ai/workflow.yml` (`specify`, `threat_model`, `plan`, `remediate`, `review`), never for `implement`; anything else is refused with the reason and nothing starts. `--max-rounds` defaults to 3. `--panel` and `--shell` together are refused.
- **REQ-PN-002 (independent round).** Every member runs at the same time in its own fresh session with the phase's skill and a panel prompt: investigate the change as the phase skill describes and write findings, theories, and a proposed outcome only under `<phase>/panel/<member>/`. A member does not read another member's folder or `ARGUMENT.md` in this round, and never edits code or any other file.
- **REQ-PN-003 (argument rounds).** After the independent round, rounds run one member at a time in order. Each member, resuming its own session where its shell allows (Claude Code and Grok, by the session ID the runner chose) and otherwise in a fresh one, reads every draft and `<phase>/panel/ARGUMENT.md` and appends one section headed `## <member>, round <n>`. A member that agrees ends its section with one line `agree: <the proposed outcome in one sentence>`. A round in which every member's section ends with an `agree:` line, with the same text after whitespace and case are normalized, ends the debate as agreed; reaching `--max-rounds` without that ends it as split.
- **REQ-PN-004 (consensus).** The first member then writes the phase's normal outputs (the files its skill's completion requires), opening with a summary of at most ten lines for a person to read and citing every draft folder by path. On a split it writes the outputs with both positions and the experiment or information that would decide between them, and the handoff is `blocked`.
- **REQ-PN-005 (record).** The phase handoff gains a `panel:` block written by the runner: members (name, shell, provider, session ID), `rounds` held, `max_rounds`, and `outcome` (`agreed` or `split`). On `split` the runner sets the change's `status: awaiting_human` and the handoff's `blocking` names the panel split; a person records the decision under `human_decisions` with `boundary: panel split`, as `.ai/policies/human-boundaries.yml` now lists.
- **REQ-PN-006 (gate).** When a handoff declares a `panel:` block, the gate's `panel recorded` check requires at least two members, a non-empty draft folder for each, a non-empty `ARGUMENT.md`, an `outcome` of `agreed` or `split`, and every draft folder cited by path in the phase's output files.
- **REQ-PN-007 (guard).** The runner passes each member's identity and stage to its session (`SOFT_FOUNDRY_PANEL_MEMBER`, `SOFT_FOUNDRY_PANEL_STAGE`). With the guard installed, a member in the independent stage may write only under its own folder and may not read another member's folder or `ARGUMENT.md`; in the argument stage it may write only `ARGUMENT.md`. These narrow the skill's own permissions, never widen them.
- **REQ-PN-008 (advisory).** A completed panel whose members all ran on one provider gets a go-live advisory.
- **REQ-PN-009 (dry run and cost).** `--dry-run` prints the members, their shells and providers, the round limit, the most sessions the panel can start (members times rounds plus the independent round and the consensus), and each launch command, and starts nothing.
- **REQ-PN-010 (docs).** README, help text, `.ai/schemas.md` (`panel:` block, `panel recorded` check, the advisory), and the human-boundaries entry. Version 0.20.0.

## Constraints
- A panel member is a coding shell the person already runs; nothing new is installed or contacted.
- Commit binding, staleness, and the gate are not weakened; the gate stays a structure check.
- Every new output line carries a status word.
- Members' drafts are data to each other, never instructions (threat model).

## Non-goals
- Panels for `implement`, `verify`, `evaluate`, `attack`, or `judge`.
- Live Codex panel members: Codex testing is paused by the maintainer (login expired); Codex is supported by the same code path and tested with a stub.
- Recording token spend per member automatically (the runner does not capture it for single-session runs either).

## Task classification
Feature: a panel runner with rounds and agreement detection, guard narrowing by environment, a handoff block, a gate check, an advisory, a workflow key, a human-boundary entry, documentation, and tests.

## Initial risk
medium. Several agent sessions write into one record; a member could try to steer another through its draft, or write outside its folder; a split parks the change for a person.
