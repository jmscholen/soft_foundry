# Architecture Review

## Scope reviewed
Placement and coupling of the new code: `PhaseSeal` (new class, one entry point `call`), `RecordFile`, `Git#observing`/`memo`/`fixed?` caching, `Git::CLEAN_ENV`, and the gate additions. Compared with `.ai/rules` baseline (small focused classes, no new dependency) and the specification's "no new gem, no CI change".

## Findings
| ID | Severity | Location | Finding | Failure it prevents | Rule or requirement |
| --- | --- | --- | --- | --- | --- |
| REV-005 | minor | `git.rb` `observing` / `memo` | Two caches coexist: a per-run `observing` block for mutable facts and an object-lifetime `memo` keyed on 40-hex SHAs. The memo is correct only because a full hash names an immutable object; `blob` and `commit?` rely on the caller passing full hashes. | None reachable today: abbreviated hashes bypass the memo through `fixed?`. A later caller that adds a ref name matching 40 hex would be cached forever, which is not a state any current input reaches. | REQ-036 |
| REV-006 | minor | `phase_seal.rb` TOOL_KEYS | The list of keys the tool moves is duplicated knowledge from `ChangeRecord#update_metadata` callers. A new tool-moved key makes the seal print a spurious "hand-edited" note. | Informational note names a key as hand-edited when the tool wrote it; no gate result changes. | ATK-007 |

## Conformance
Conforms. The seal reuses the record lock, `update_metadata` and `update_handoff`; the commit is staged by explicit path (REQ-033). Layering matches the surrounding code and no dependency was added.
