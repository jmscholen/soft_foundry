# Mitigations

| ID | Threats | Mitigation | Where enforced | Verified by |
| --- | --- | --- | --- | --- |
| MIT-001 | THREAT-001 | Resolve the slug against the list of existing change directories (summary) or a strict slug pattern (new); never join an unvalidated string into a path; refuse with the known names | `change summary` and `change new` argument handling | ATK-001 |
| MIT-002 | THREAT-002 | Escape ESC, other control characters, carriage returns and bidirectional controls in every free-text value echoed by `summary` and `blocked:`; one fact per line so a newline in text cannot forge a prefix line; no styling outside a TTY | Output formatting shared by new commands | ATK-002 |
| MIT-003 | THREAT-003 | The phase name for the write comes from the runner's own argument, not handoff content; the write targets only that phase's `handoff.yml` and changes only `status` and `notes`; blocking entries preserved byte for byte | Runner finish path | ATK-003, ATK-004 |
| MIT-004 | THREAT-004 | Blocked write uses the existing record-locked handoff update; on lock failure print `warn:` and leave the handoff as written, exit nonzero; same path for single, parallel and auto-reopened runs | Runner finish path | ATK-003 |
| MIT-005 | THREAT-005 | Gate rule unchanged: `complete` with non-empty `blocking` fails; runner marks `blocked`; the phase must be redone, not edited; residual risk that blockers are written elsewhere stays with review, since the gate checks structure only | Gate, runner | ATK-005 |
| MIT-006 | THREAT-006 | Gate requires `in_force` on at least one check or a stated value and note on every check; `disabled` needs a non-empty note; the rule text states the gate verifies presence, not truth, and review checks the claim against the run log; claims are reviewed in phase 13 | `protection stated` gate check, `.ai/rules/` parity rule | ATK-006 |
| MIT-007 | THREAT-007 | Unreadable or invalid glob fails the check with the existing `access_control` lint message; no glob and no match is the only not-applicable path; matching is pure glob on paths, no shell | Gate check | ATK-007 |
| MIT-008 | THREAT-008 | Exact-match against one constant list (no case folding or trimming that widens); refuse before creating anything; `check` lints the constant against template comments and `workflow.yml`; forced-by-risk track rule retained; risk waivers still bounded by `waivable_by_risk` | `change new`, `check` | ATK-008 |
| MIT-009 | THREAT-009 | Guidance written with visible escapes and no raw hidden characters; scanner unchanged and run by `check` over the edited files | Skill and README text, `check` content scan | ATK-010 |
| MIT-010 | THREAT-010 | Bounded read size for handoffs in the summary; safe loader with aliases limited; echoed lists truncated with a count; unreadable shown with a reason | `change summary` | ATK-009 |

## Residual risk
The gate and summary report recorded structure, not truth. A verification agent can claim `in_force` falsely; only review and the run log detect it. Terminal escaping covers the CLI; the read-only `ui` page is out of scope and already escapes text.
