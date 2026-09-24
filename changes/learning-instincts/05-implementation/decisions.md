# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Instincts are a YAML list per record, validated by the learning gate | Free-form in `findings.md`; a repository-wide ledger | A gate can validate a list; `learn list` can read it across records; the evidence stays beside the lesson | `instincts.yml` is a required learning file; an empty list is valid |
| Promotion is a command that refuses outside a change record | Auto-promote at close; a `--force` from `main` | The governance path is the capability being built; a rule change on `main` with no record is the gap the closure-gap memory describes | `learn promote` names the record it went through |
| A closed record still contributes instincts | Only open records | Lessons outlive changes | `Learning.all` reads every record |
| The threshold is policy with a per-run override | Hard-coded 0.8 | A repository may want stricter promotion; a person may want to promote one lesson | `.ai/policies/learning.yml`; `--min-confidence` |
| Idempotence by `## <id>` heading | A promoted-ids ledger | The rules file is the ledger; a heading is what a person sees | A hand edit that renames a heading re-promotes; acceptable, since a hand edit is a change |
| `learned.md` is a baseline rule for implementation and exploration | Also review; only implementation | The two skills that write code are the ones that act on instincts; review reads every rule already | Two lines in two `skill.yml` files |
| This change completes its own learning phase | Leave it pending like every prior record | The capability is unproven until one record has instincts the gate validated; `learning.finding_capture` becomes PASS on that fact | Six instincts from this series; the next change can promote them |
