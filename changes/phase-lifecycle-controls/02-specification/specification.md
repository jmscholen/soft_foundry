# Specification

## Intent
Three controls, answering items 4-6 of field feedback, implemented generically for any adopter (change B; item 7 is change C):

1. **Phase reopen** on every track: `phase reopen <phase> --reason TEXT` resets a phase and its downstream phases through the tool, records why, and `phase run` calls it automatically when a phase's evidence is stale. This replaces hand-editing handoffs with `sed`.
2. **Parallel isolated runs**: `phase run <phase> <phase>... --parallel` runs phases that `workflow.yml` declares isolated (evaluate, attack) concurrently, each with an adopter-supplied per-run environment value, without corrupting the record or confusing the permission guard.
3. **Released state**: `change release` records `status: released` with named open items so `main`'s CI passes while the record shows what is owed; `change discharge` and `change close` bring it to the one end state, `closed`.

Out of scope: item 7, scoped-verification follow-ups, parallelising non-isolated phases, any change to the iterative track. Requirements are REQ-001 to REQ-027; criteria AC-001 to AC-051.

## Personas and authorization boundaries
- **Maintainer / engineer** (a person at a terminal or CI): may run `phase reopen`, `phase run [--parallel]`, `change release`, `change discharge`, `change close`.
- **Phase session** (an agent run by `phase run` with only its own skill): may do its skill's work only. It may not run `phase reopen`, `change release`, or `change discharge` (REQ-007, REQ-018); the runner marks its environment so the commands can refuse.
- **Runner**: the only actor that auto-reopens, before a session starts.
- **CI**: runs `check` and `ci`; reads the released record, never writes it.
- No authentication or credentials are introduced. Authorization is by who may invoke a command, enforced by the session marker and the existing guard. `--env` values may carry adopter credentials and are never persisted (REQ-012).

## Functional behavior
**Reopen (REQ-001..008).** Downstream of P = lifecycle successors of P (including optional, loop, and waived phases) plus `transitions` targets, to a fixed point; already-pending phases are skipped. Reset sets handoff `pending`, clears `commit_sha`, `completed_at`, `executed_by`, `outputs`, appends a note, and leaves all evidence files untouched. History goes to a new `metadata.yml` list `phase_reopenings` (not `reopenings`, which stays the exploring return). `current_phase` becomes the reopened phase, `judged` becomes `in_progress`. Allowed statuses: intake, in_progress, judged. Reopening specify or earlier is the recorded requirement change for a locked specification. `phase run` auto-reopens a complete-but-stale phase (source `auto`), then runs it; a complete phase with current evidence is still refused.

**Parallel (REQ-009..016).** `workflow.yml` gains `isolated_phases: [evaluate, attack]`, linted by `check`. `--parallel` takes two or more isolated phases, validates everything first (nothing starts on any refusal), and a named phase whose predecessor is another named phase is allowed to start. `--env NAME=VALUE` (repeatable; `{phase}` expands per phase) is passed to each session; Soft Foundry never provisions anything; with no `--env` a `warn:` line states isolation is the adopter's job. Each session receives a marker naming its phase, and the guard resolves the active skill from it before `current_phase`. Sessions are told not to commit; all phases record the start HEAD; the runner prints `phase <id>: pass|fail` per phase and exits non-zero if any failed or HEAD moved.

**Released (REQ-017..021).** `change release --item ID=DESCRIPTION...` requires lifecycle end, a complete APPROVED / APPROVED_WITH_RESIDUAL_RISK judgment, and at least one valid item; judgment `undischarged` items are carried over under their own ids so there is one still-owed list. It does not require the change to be merged (the record must be on the branch for `main`'s CI to see it). `change discharge ITEM-ID --note TEXT` discharges one item. `change close` of a released record needs all items discharged (`--force` as today). `ci` on a merged change: closed skipped; released with open items passes with a `released:` line and an advisory; released with none open fails ("run change close"); anything else fails as today. Consumers: not gate-evaluated and no scope claim (like closed), displayed as released with its open-item count, no active skill, `phase run`/`reopen`/`release` refused.

## Accessibility
`surfaces.accessibility` is true: the changed surfaces are CLI output, the UI's open/closed counts, and documentation. REQ-024 applies `.ai/rules/accessibility.md` command-line rules (outcome words, stable prefixes, no ANSI off a TTY, no prompts, actionable errors). REQ-025 requires the UI to show released as text plus a count in a list/table with headers (WCAG 1.4.1, 1.3.1, 4.1.2, 1.4.3, 1.4.11) and docs with a real heading hierarchy. Findings against this standard are go-live advisories per the rule.

## Data and consistency
New `metadata.yml` keys: `phase_reopenings` (list; entry shape in REQ-004) and `release` (`at`, `commit`, `items[{id, description, discharged_at?, discharge_note?}]`); status vocabulary gains `released`. Records without the keys remain valid. Handoff schema unchanged. Record writes by the runner and new commands are serialised under a lock (10 s bound) and written atomically; a reopen's resets and history entry are applied together or not at all (REQ-014, REQ-022). Parallel evidence binds to one HEAD (REQ-015).

## Failure behavior
REQ-022 lists every refusal: reopen (unknown phase, bad reason, wrong status, nothing to reset, inside a session), parallel (any pre-flight refusal starts nothing; a missing shell fails that phase only), release/discharge (every refusal writes nothing). Lock timeout fails without writing. Errors name the problem and the next step. An interrupted parallel run signals every child and leaves parseable YAML with the phases `in_progress`, as a single run does today.

## Security requirements
- No forged evidence: reopen resets state only, requires a recorded reason and commit, never edits evidence files, never marks a phase complete, and does not touch `implementation_may_not_grade_itself`, `final_judgment_required`, or any phase's requirements (REQ-007).
- Commands that rewrite the record's lifecycle state refuse inside a phase session (REQ-007, REQ-018).
- Guard: per-session phase marker with strict handling of unknown or non-isolated values; honoured only because only the runner sets it (REQ-013). The threat model should examine an agent shadowing the marker inside a command.
- `released` is not a skip route: judgment required, items required, carry-over of undischarged items, `ci` still fails neither-closed-nor-released (REQ-018).
- `--env` values never persisted or printed; names constrained (REQ-011, REQ-012). Free-text reason, descriptions, and notes are length-capped and control-character-free so they cannot inject into the record or logs.

## Privacy and security policy conformance
`surfaces.policy` is false. This change collects, shares, retains, protects, and promises nothing new: no published privacy policy, security policy, or terms exist for Soft Foundry (`.ai/repository.yml` `policies:` records privacy, security, and terms NOT_APPLICABLE; there is no SECURITY.md, PRIVACY.md, or TERMS.md, re-established in discovery). The only sensitive datum the change touches is the adopter's `--env` value, which is passed through to the local session and never stored (REQ-012), so no policy clause is engaged. No `category: policy` requirement is needed.

## Performance and resource limits
REQ-016: parallel wall-clock is the slowest session plus under one second; `phase reopen` under one second. Lock wait bounded to 10 s. Reason and description text capped at 500 characters. No memory or storage concern beyond a few history lines per reopen.

## Infrastructure implications
None. No deployed service, database, or IaC. GitHub Actions already runs `soft-foundry ci` and the suite; `released` changes only how `ci` treats a merged record.

## Observability expectations
No service to monitor (`surfaces.observability` is false). Observability is the record and the output: history entries for reopen/release/discharge, the snapshot timeline showing phase reopens distinct from exploring reopens, auto reopens labelled, open items listed by `change status` and `ci` (REQ-026).

## Acceptance criteria
AC-001..AC-051 in `acceptance-criteria.yml`, each mapped to requirements and each stated as a fixture-checkable given/when/then (stub shells stand in for coding shells; no network). Open design choices left to planning, none blocking: the lock mechanism and file, the marker variable name, the CLI wording of messages, how the guard learns the isolated list, and how evidence of parallel runs is committed after the run (the runner does not commit; the person commits once).
