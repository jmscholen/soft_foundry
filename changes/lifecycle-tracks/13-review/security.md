# Security Review

## Scope reviewed
New writes: `metadata.yml` and hardening-phase handoffs, rewritten by `vet!`/`reopen!` on a person's command; `exploration/iterations.yml` scaffolded by `change new`. New reads: git `user.name` (`Git#user_name`), `iterations.yml`, the `tracks:` block, the profile's `environments:`. New free-text inputs: `--by`, `--reason`, `--track`.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-012 | info | `lib/soft_foundry/cli.rb` `change_vet`, `change_reopen` | `--by` and `--reason` are written through `YAML.dump`, which quotes as needed, so a value containing `: ` or a leading `#` cannot break the file (EVAL-006 wrote a reason with spaces and parentheses). `--track` is validated against the defined names before anything is created. | `.ai/rules/security.md` |
| REV-013 | info | `lib/soft_foundry/change_record.rb` `iterations` | Journal entries are read with `safe_load_file` and filtered to hashes; a malformed journal reads as empty and makes `vet` refuse rather than raise. Only `deployed.environment` and the count reach the terminal. | `.ai/rules/security.md` |
| REV-014 | info | `lib/soft_foundry/git.rb` `user_name` | Reads local git config only; the value lands in a committed record as `vetted.by`, the same identity git already records on every commit. | `.ai/rules/security.md` |
| REV-015 | info | `vetted` and `reopenings` | Recorded, not authenticated: anyone with write access to the record can write a vet by hand. Same trust model as `change close --confirm` and `human_decisions`; the record is what the merge reviewer reads. | `.ai/policies/human-boundaries.yml` |

## Conformance
Conforms. No new attack surface beyond what `metadata.yml`'s threat_model rationale records.
