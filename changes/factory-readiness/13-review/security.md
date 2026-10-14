# Security Review

Commit reviewed: a9fac32d0c0e2d8951ee09ed0a5c9a8102c34637.

## Scope reviewed
`03-threat-model/` (THREAT-001 to -007, MIT-001), `08-attack/` (four rounds, final at 9806b2b), `Guard` (symlink resolution, `cd`/glob/brace tracking, fail-closed rescue, `SELF_PROTECTED`, baseline restore), `HarnessEval` input limits (64 KiB per case), `Hooks`. I read the guard diff in full and the attack evidence summaries; I did not rerun attacks.

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-002 | major | `guard.rb` `record_baseline!`/`check_after!`; ATK-F10 remainder | Three same-user routes still defeat the post-call restore: a detached process writing after the check, one command rewriting the policy and the baseline together, and a weak policy committed with the baseline deleted. The record accepts them as residual (REM-005). Accepted-residual status is a judgment call, not a review closure. | A steered session with a shell runs `( sleep 2; printf 'guard: {mode: warn}' > $P ) &` with the path in a variable; the next call finds warn recorded as baseline and a Write to the policy is allowed with a warning. Traces remain (guard log, git history, diff). | THREAT-001, MIT-001 |
| REV-003 | minor | `guard.rb` Grep/Glob and shell read handling | A root-wide search (`Grep` with no path, `grep -r .`, `find`) still reaches `.ai/harness-evals/` (ATK-F9, accepted in REM-004). | An implementation session reads the eval cases and tailors work to them; fresh-context review and attack still apply. | THREAT-003 |
| REV-008 | minor | `gate.rb`, handoff `commit_sha` | A handoff's `commit_sha` is self-attested and not compared with the commit that wrote it (ATK-F3). | A session stamping an older SHA on newer evidence passes `evidence current` if the code did not change since the stamped SHA; git history shows it. | AGENTS.md rule 9 |

No new vulnerabilities found beyond the attack record. Specifically checked: `resolve_links` falls back to the unresolved path on `SystemCallError`, which is safe because `decide` also rescues; `check_after!` deletes a symlinked settings file rather than writing through it; `read_text` scrubs invalid bytes so a stray byte cannot crash a gate check into a pass; `waivers_check` refuses review and judgment at every risk. No secrets, no network calls, no new dependencies. Evidence from the attack phase used synthetic data in scratch repositories.

## Conformance
Conforms with advisories. REV-002 is the substantive residual; it needs an explicit judgment decision (APPROVED_WITH_RESIDUAL_RISK is the fitting class) rather than silence.
