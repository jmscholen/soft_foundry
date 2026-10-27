# Specification

## Intent
Five small fixes that remove everyday friction, built generically for any adopter (item 7 of the field feedback):
1. `change new` records task type and risk at creation.
2. The phase runner marks a handoff `blocked` when a session wrote `complete` while listing blocking items.
3. Skill guidance tells agents how to quote invisible or control characters in evidence.
4. A short per-change latest-state summary.
5. An access-control parity rule: verification states whether the protection was in force.

Nothing assumes a framework, database or provider. Existing flags, commands and record formats keep working; a record without the new fields stays valid. The gate and `ci` keep checking structure, not truth.

## Personas and authorization boundaries
- **Maintainer / adopter engineer** runs `soft-foundry` commands locally or in CI; no authentication or authorization is added, and nothing leaves the machine.
- **Phase-run agent** writes only inside its phase directory. The runner (not the agent) performs the blocked-marking write, and only to the handoff of the phase it just ran. Another phase's evidence is never edited.
- **Verification agent** records the protection state; it may not weaken the check by omitting the field.

## Functional behavior
**F1 Type and risk at creation.** `change new <slug> --type TYPE --risk RISK` writes `type` and `risk` to `metadata.yml`. Allowed types: feature, fix, refactor, docs, infrastructure, security, chore. Allowed risks: low, medium, high. An unknown value is refused before anything is created, naming the flag, the value and the allowed list. Omitting a flag leaves the template placeholder (`the placeholder value`) as today. `--risk high` combined with a non-gated `--track` is refused exactly as the forced-by-risk rule refuses it today. The allowed values have one source of truth that `check` verifies agrees with the metadata template comments and `.ai/workflow.yml` risk names.

**F2 Blocked marking.** When a phase-run session leaves a handoff with `status: complete` and a non-empty `blocking` list, the runner rewrites `status` to `blocked`, keeps the `blocking` entries unchanged, appends a sentence to `notes` saying the runner changed it, and prints a line starting `blocked:` that names the phase and the number of blocking items. This applies identically to single runs, `--parallel` runs and runs that auto-reopened a stale phase. A handoff with `complete` and empty `blocking` is untouched. The gate still fails a hand-edited `complete` handoff with blocking items; the runner's write does not change gate rules.

**F3 Invisible-character guidance.** The adversarial-testing, verification and review skill guidance, and the README content-scan section, state that payloads containing invisible, zero-width, bidirectional or control characters are written into evidence as visible escapes (for example `<U+200B>` or `<U+200B>`) or built inside a script, never pasted raw. The scanner's behaviour is unchanged.

**F4 Latest-state summary.** `soft-foundry change summary [slug]` (slug defaults to the current branch's change) prints, from recorded files only (metadata, handoffs, findings, advisories already stored), one line per fact, each with a stable prefix:
- `change:` slug, track, risk, status;
- `phase:` current phase;
- one `phase-status:` line per lifecycle phase with its recorded status word (complete, in_progress, pending, blocked, skipped, stale where already derivable);
- `findings:` count of findings per phase that has any, by severity where the handoff states one, otherwise a total;
- `blocking:` each blocking item with its phase, or `none`;
- `owed:` each open human decision, release item or advisory, or `none`.
It does not run the gate and writes nothing. An unknown slug is refused with a message naming the known changes.

**F5 Access-control parity.** `.ai/rules/` gains an access-control parity rule. The repository profile's existing `access_control` globs name the protected paths. When a change's changed files match any of them, the verification record's checks must state the protection state they ran with. `tests.yml` gains an optional per-check field `protection` with values `in_force`, `disabled` or `not_applicable`, and `protection_note`. A check with `disabled` must have a non-empty `protection_note` giving the reason. The gate adds a structure-only check, `protection stated`, which requires that when the profile declares `access_control` and a changed path matches, at least one check states `protection: in_force`, or every check states a value and a note explaining why none ran with it in force. When the profile declares no `access_control`, or no changed path matches, the check is not applicable and the record is unaffected.

## Accessibility
The new surfaces are CLI output (F1 refusal text, F2 `blocked:` line, F4 summary) and Markdown guidance text. They follow `.ai/rules/accessibility.md` (WCAG 2.2 AA applied to command-line output): outcomes are words, not glyphs or colour; no ANSI styling unless a TTY and `NO_COLOR` unset; one fact per line with stable searchable prefixes; no layout that depends on terminal width; no prompting; errors say what went wrong and what to do next. Markdown additions keep a real heading hierarchy and use a table only for tabular data with a header row.

## Data and consistency
- New stored fields are optional and additive: `type`/`risk` values reuse existing keys; `tests.yml` gains `protection` and `protection_note`. Older records without them remain valid.
- The summary stores nothing and derives from existing files, so it cannot disagree with them except by staleness of what it reads.
- The runner's blocked write goes through the record-locked handoff update already used for handoff writes, so a concurrent `--parallel` finish does not lose it.
- Changing the allowed vocabulary or the parity rule files edits control-plane text; existing evidence staleness rules apply and are not altered.

## Failure behavior
- Unknown `--type` or `--risk`: nonzero exit, no record created, message lists allowed values.
- Blocked-marking write fails (lock timeout, unreadable handoff): the runner reports the failure with a `warn:` line, leaves the handoff as the session wrote it, and exits nonzero as it does for other finish failures; the gate then fails it as before.
- Summary with a missing or malformed handoff: that phase is shown with status `unreadable` and the reason on its own line; the command still prints the remaining facts and exits zero.
- Parity check with an unreadable profile glob follows the existing `access_control` lint failure; it does not silently pass.

## Security requirements
No new trust boundary, credential, network call or privilege. The runner may write only the handoff of the phase it just finished. The guidance in F3 reduces the chance that raw hidden characters enter evidence that is read as instructions. The parity rule exists so verification cannot pass only with a protection disabled for convenience without saying so. The gate does not verify that a claim is true; the stated limits are recorded in the rule text.

## Privacy and security policy conformance
`surfaces.policy` is false. Nothing the application collects, shares, retains, protects or promises changes: all five fixes act on local repository files and CLI output; no personal data, telemetry or network use is added, so no published privacy policy, security policy or terms clause is touched.

## Performance and resource limits
The summary reads at most one metadata file and sixteen handoffs and finishes without running the gate; it should return in well under one second on a normal record. Blocked-marking adds one handoff read-modify-write per phase run. Option validation is constant time.

## Infrastructure implications
None. No deployment, IaC or CI workflow change; the existing test suite and `ci` cover the work. A version bump and release notes are a plan decision.

## Observability expectations
No service telemetry applies (`surfaces.observability` is false). The operator-visible signals are the CLI lines: `blocked:` from the runner, `summary` facts from F4, and the gate's `protection stated` check result. Each is a plain-text line searchable in CI logs.

## Acceptance criteria
See `acceptance-criteria.yml` (AC-001 to AC-020), each mapped to a requirement in `requirements.yml`.

## Resolved design questions from discovery
- Vocabularies: types and risks as listed in F1, held in one constant that `check` lints against the template comments and `workflow.yml`.
- `blocked` wording: status `blocked`, existing `blocking` entries kept, explanation appended to `notes`, `blocked:` stdout line.
- Parallel and auto-reopened runs behave like single runs.
- Summary: command `change summary`, recorded state only, layout above.
- Finding counts source: each handoff's `findings:` list; severity is used only where the entry states one.
- Guidance targets: adversarial-testing, verification, review, README.
- Parity record: `protection` / `protection_note` in `tests.yml`; gate requires it for verification only, not evaluation or attack.
- Soft Foundry's own records are unaffected: this repository declares no `access_control`.
- Routing of skill and rule edits to a phase with write access, harness-eval case content, and the version bump are left to the plan.
