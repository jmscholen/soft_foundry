# Proposed Harness Evals

Written without reading `.ai/harness-evals/` (denied to this skill). Check each against existing cases before adopting.

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| gate case: unparseable specification YAML | A record whose `requirements.yml` does not parse with `YAML.safe_load` is refused at the specification or later gate | REC-001 | `soft-foundry gate specification` fails and names the file and line |
| gate case: renamed file leaves record current | A scoped record whose file is renamed out of its scope goes stale | ATTACK-013 | `gate verify` reports `evidence current` as stale, naming the source path |
| gate case: ref created after evidence | A `git.branch` named before the ref exists, created later, does not make later code on the checked-out branch unmeasured (blocked until the owed measure change exists; expected to fail today) | REV-001, ATTACK-019 | `gate verify` fails stale after `lib/a/x.rb` lands |
| gate case: stacked branch control | A change stacked under another is measured on its own branch | ATTACK-021 | current while code lands only above; stale after a commit on its own branch |
| gate case: scalar `git:` metadata | A `git:` that is a string yields a gate line naming the field, not a Ruby error | REV-004 | exit 1 with the field named, no `#dig` text |
| gate case: case-folded citation slug | A cited verification slug differing only in case is refused | ATTACK-016 | `gate verify` fails with a slug-mismatch line |
