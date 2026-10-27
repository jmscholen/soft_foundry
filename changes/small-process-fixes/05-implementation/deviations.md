# Deviations From Plan

## DEV-001: control-plane text edits not made (REQ-007, REQ-011, part of REQ-012)
- What changed: the plan listed `.ai/rules/access-control-parity.md` (new), `.ai/skills/adversarial-testing/SKILL.md`, `.ai/skills/verification/SKILL.md`, `.ai/skills/review/SKILL.md`, and `.ai/skills/verification/template/tests.yml` (optional `protection` and `protection_note`). None is written.
- Why: the implementation skill's `permissions.yml` writes only `${APP}`, `${TESTS}`, `${INFRA}` and this phase directory, and lists `${CONTROL_PLANE}` under `deny_write`. The plan said that if this were so the files go to a person as a recorded human decision and no other skill does them to obtain a pass.
- Requirements affected: REQ-007 (invisible-character guidance in three skills and the README), REQ-011 (the parity rule), and the template half of REQ-012. The gate check itself (REQ-013, REQ-014) is implemented and works without the template lines; the fields are optional.
- Approval needed: a person (or a phase allowed to write `.ai/`) must add the five files above. The new text must use visible escapes for hidden characters and pass `soft-foundry check`.

## DEV-002: README, `.ai/schemas.md`, gemspec and harness-eval cases not touched
- What changed: no README section for `change new --type/--risk`, `change summary`, the `blocked:` line, or the content-scan guidance; no `.ai/schemas.md` entry for `protection`; no harness-eval cases; the version constant is bumped but the gemspec was not read or changed.
- Why: `README.md` and `.ai/schemas.md` are outside this skill's write set (DOCS and CONTROL_PLANE are denied), and `.ai/harness-evals/` is denied for read and write.
- Requirements affected: REQ-007 (README half). Unit and integration tests carry the coverage meanwhile (as testing.md anticipated).
- Approval needed: a later phase with write access, or a person.
