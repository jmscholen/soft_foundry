# Implementation Plan

## Approach
Five small, independent fixes built in this order so each can be verified alone and a failure points at one change. All shared helpers come first.

implementation_sequence:
1. Shared output escaper: one function that replaces ESC, other control characters, carriage returns and bidirectional controls with visible `<U+XXXX>` text, truncates long lists with a count, and is used by every new line that echoes recorded text (THREAT-002, MIT-002). Mitigates before use by F2 and F4.
2. F1 vocabularies and `change new`: one constant holding the allowed types and risks (exact match, no case folding or trimming); `--type` and `--risk` parsed in `cli.rb` `change new`; slug checked against a strict pattern before any path join (MIT-001, MIT-008); refusal before anything is created, naming flag, value and allowed list; `--risk high` with a non-gated track refused by the existing forced-by-risk rule. `ChangeRecord.create` takes `type:` and `risk:` and writes them; omitted values keep the template placeholders. `check` lints the constant against the metadata template comments and `workflow.yml` risk names (REQ-003).
3. F2 blocked marking: `PhaseRunner#finish!` (or a new `mark_blocked!` called straight after it) reads the just-finished phase's handoff through the record-locked `update_handoff`, and when `status` is `complete` and `blocking` is non-empty sets `status: blocked` and appends a sentence to `notes`. The phase is the runner's own argument, never derived from handoff content; only `status` and `notes` change; `blocking` is untouched. The caller prints `blocked: <phase> has N blocking item(s)`. Called from the single-run site (`cli.rb` ~1120) and the parallel site (~1233), and covers auto-reopened runs because they reach the same finish path. On lock or read failure: `warn:` line, handoff left as written, existing nonzero exit.
4. F4 `change summary [slug]`: new subcommand in `cli.rb` (`change` case) backed by a small reader in `snapshot.rb` that loads metadata and each phase handoff with a bounded read size and the safe YAML loader with aliases limited. Prints `change:`, `phase:`, one `phase-status:` per lifecycle phase, `findings:`, `blocking:`, `owed:`; an unreadable handoff prints status `unreadable` plus a reason line and the rest still prints with exit zero. Slug resolved against the existing change directory list; unknown slug refused naming the known changes. Never runs the gate, never writes. Output goes through the escaper and only styles on a TTY with `NO_COLOR` unset.
5. F5 parity: `tests.yml` template gains optional `protection` and `protection_note`; `gate.rb` gains a structure-only check `protection stated`, registered for the verification phase only. Applicable only when the profile declares `access_control` and a changed path (from the same changed-file source the scope and sizing checks use) matches by pure glob; otherwise not applicable and the record is unaffected. Rules: at least one check `in_force`, or every check states a value with a non-empty note; `disabled` requires a non-empty `protection_note`. An unreadable or invalid glob fails with the existing `access_control` lint message, never passes silently (MIT-007).
6. F3 guidance text and the parity rule file (see Control-plane text edits below).
7. Docs and version: README, `.ai/schemas.md`, version bump 0.21.0 to 0.22.0 (additive behaviour, new commands and fields; minor bump).

## Application changes
affected_files_or_components:
- `lib/soft_foundry/cli.rb`: `change new` options and usage text; `change summary` dispatch; `blocked:` and `warn:` printing at both run sites.
- `lib/soft_foundry/change_record.rb`: `create` accepts `type:` and `risk:`.
- `lib/soft_foundry/phase_runner.rb`: blocked marking.
- `lib/soft_foundry/snapshot.rb`: summary reader.
- `lib/soft_foundry/gate.rb`: `protection stated` check and `tests.yml` field validation.
- `lib/soft_foundry/check.rb` (and `control_plane.rb` for the vocabulary constant): vocabulary lint.
- A new small output-escaping helper under `lib/soft_foundry/` (name chosen by the implementer to match existing files).
- `lib/soft_foundry/version.rb`, `soft_foundry.gemspec` if it pins the version, `README.md`, `.ai/schemas.md`.

Control-plane text edits (routing). The planning, implementation and other phase skills cannot write `.ai/` (CONTROL_PLANE is in deny_write for the plan skill; the implementation skill's allowance was not read here). The implementer must confirm that the implementation phase's `permissions.yml` lists `${CONTROL_PLANE}` for write. If it does not, these files are handed to a person as a recorded human decision and the change parks at `awaiting_human`; no other skill is to do them to get a pass. Files: `.ai/rules/access-control-parity.md` (new), `.ai/skills/adversarial-testing/SKILL.md`, `.ai/skills/verification/SKILL.md`, `.ai/skills/review/SKILL.md`, `.ai/skills/verification/template/tests.yml`, `.ai/templates/change/metadata.yml` only if the comments need aligning with the constant. All new text uses visible escapes, no raw hidden characters; the content scan in `check` is run over it.

Harness-eval cases (gate case for `protection stated`, blocked marking) live in `.ai/harness-evals/cases/`, which this phase may not read. They are not planned in detail: the implementation phase adds them only if its permissions allow, and otherwise the gap is recorded as an open item. Unit and integration tests below carry the coverage meanwhile.

## Database changes
N/A. No database.

## Infrastructure changes
N/A. No deployment, IaC or CI workflow change.

## Test strategy
See `testing.md`.

## Rollout
See `rollout.md`.

## Rollback
See `rollback.md`.

## Risks
- risks: R1 the blocked write races the session's final write or a parallel finish; mitigated by the record-locked update and a test with two finishes (THREAT-004). R2 control characters in echoed text forge lines; mitigated by the shared escaper applied everywhere new output echoes text (THREAT-002). R3 vocabulary drift between the constant, template comments and `workflow.yml`; mitigated by the `check` lint (THREAT-008). R4 the parity gate is presence-only, so a false `in_force` claim passes; accepted residual, stated in the rule text and left to review (THREAT-006). R5 an access-control glob that matches too much makes the check noisy; mitigated by using the profile's globs as declared and failing visibly on invalid ones. R6 skill and rule edits may not be writable by the implementation phase; handled by the routing note above. R7 the summary reading very large handoffs; mitigated by a size cap and alias limit (THREAT-010). R8 Soft Foundry's own records gain no risk: this repository declares no `access_control`, so F5 is not applicable here.
