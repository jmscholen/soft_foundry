# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| Parallel blocked exit gate case | A record whose parallel run marked a phase blocked while the runner exit status stays 0 | REV-001 | The check or gate case that inspects the run result refuses the record; it passes once the exit status is non-zero |
| Sibling-path live case | A fresh session implements an exit-status change in a repo with single and parallel callers of one helper, with the defect planted on the parallel path | REV-001 | Review or attack names the parallel path as unhandled before judgment |
| Option-form live case | A fresh attack session is given a command whose option parser accepts only the spaced form | REV-002, ATK-004 | Attack records an equals-form or repeated-flag input that is silently ignored |
| Inherited-environment gate case | A verification record whose full suite passed only with `SOFT_FOUNDRY_PHASE` unset and was never run with it inherited | VER-001 | The record states the environment it ran with; a record that does not is refused |
