# Functional Review

## Scope reviewed
Every requirement in `00-intake/request.md` (REQ-LRN-001 to REQ-LRN-008) against commit `a5648d0b`: `lib/soft_foundry/learning.rb`, `Gate#instincts_check`, the `learn` command, the template, completion, policy, rules file, baseline entries, documentation, profile and maturity edits, `test/learning_instincts_test.rb`, the RED commit `a5c0d59`, this record's own `15-learning/`, and the evaluation transcript.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-001 | minor | `lib/soft_foundry/learning.rb` `problems` | The per-problem prefixing uses a regex substitution to avoid "id: id ..." doubling; it works for the tested cases but is the kind of string handling a small formatter would make obvious. Follow-up. | REQ-LRN-002 |
| REV-002 | info | `lib/soft_foundry/cli.rb` `learn promote` | Promotion refuses on a closed record but not on a record that is still at `intake`; a change that exists only to promote (like the journey's `promote-1`) is exactly that, so this is right. | REQ-LRN-005 |
| REV-003 | info | `lib/soft_foundry/learning.rb` `all` | Reads every record's `instincts.yml` on each `list`/`promote`; fast today (thirteen records), linear in records. No cache, by choice. | REQ-LRN-003 |
| REV-004 | minor | `learned.md` idempotence | Keyed by `## <id>` heading, so two records that learn different lessons under the same id collide: the first promoted wins and the second is skipped as "already in". The gate enforces id uniqueness within a record, not across records. Follow-up: warn when a skipped id's trigger differs from the promoted one. | REQ-LRN-004 |
| REV-005 | info | this record's `15-learning/instincts.yml` | Six instincts, each with evidence naming a finding or phase in this series' records; the gate prints `6 instincts` by id. The first completed learning phase in the repository. | REQ-LRN-008 |

## Conformance
Conforms. Every requirement is implemented and exercised: REQ-LRN-001 and 002 by the template and gate tests and EVAL-001; REQ-LRN-003 by the list test and EVAL-002; REQ-LRN-004 to 006 by the promote tests and EVAL-003/004; REQ-LRN-007 by the baseline test and EVAL-005; REQ-LRN-008 by this record's learning phase, the profile, and the maturity rules.
