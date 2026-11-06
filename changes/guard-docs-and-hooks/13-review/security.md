# Security Review

## Scope reviewed
- The hook entries committed in `.claude/settings.json` and `.codex/hooks.json`: content equal to the installer's constants (`hooks.rb` 52 to 53, 65, 87 to 88); no secret, no path outside the repository, no network call. The command strings prefer this checkout's own code over an installed gem, as in every repository the installer writes.
- `.ai/policies/enforcement.yml`: `guard.mode: block` unchanged; only the header comment changed (`b9f4d7c` diff).
- The new README and user page as a public description of the guard's limits: the "what can still get past it" list matches the accepted residual of factory-readiness (REM-004 to REM-006, ATK-F10 remainder) and the header. Publishing the limits adds nothing an attacker with a shell in the repository could not read from `guard.rb`.
- The probe in `evidence/off-override-probe.rb`, for whether REV-GDH-001 opens anything.
- `.ai/rules/security.md` and `.ai/rules/access-control-parity.md`: the repository profile declares no `access_control` globs, so no verification check carries `protection`, and the parity rule has nothing to apply to.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-GDH-001 | major (see functional.md) | `cli.rb` `guard` and `guard_after`; documented in README and user page | Security reading of the finding: the off-mode post-call behaviour fails toward the stricter mode (the override is removed and the committed policy restored), so no session gains latitude from it. It is an availability and trust defect for the maintainer, not an exposure. Probe case C shows a second effect worth naming: with `SOFT_FOUNDRY_GUARD=off`, an uncommitted hand edit to `.ai/policies/enforcement.yml` is reverted to HEAD at the first shell command, which could silently discard a maintainer's in-progress policy edit. | See functional.md. Nothing is exposed; a maintainer's own configuration or edit is lost. | `.ai/rules/security.md` (fail closed is kept); REQ-GDH-004 |

No other security finding. The documentation does not weaken any control: block mode stays the repository policy, the override and the variable remain the maintainer's and are refused to every skill from the shell and the write tools (confirmed live this session for the shell), and the guard log remains machine-local and gitignored (`.gitignore` lists `.soft-foundry/`). The evidence files written by this phase contain no hidden characters and no secret-shaped strings.

## Conformance
Conforms. No new control, no weakened control, no new data flow. REV-GDH-001 is recorded here for completeness because its subject is the guard; its severity is set in functional.md.
