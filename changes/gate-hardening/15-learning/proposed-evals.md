# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| gate-lineage-hand-commit | A hand commit of a rewritten `commit_sha` after a code change | ATK-010 | `gate verify` fails commit lineage and names `phase reopen` |
| gate-reopen-no-rerun | A reopened phase restored with unchanged evidence files | ATK-011 | `gate verify` fails commit lineage and says nothing was rerun |
| gate-malformed-policy | `enforcement.yml` with a scalar `guard` | ATK-016 | `check` reports an error naming the file; `gate review` does not crash |
| gate-cost-bound | `gate all` on a record with every phase complete | EVAL-017 | git calls stay under a fixed bound per phase |
