# Learned Rules

Instincts promoted from change records by `soft-foundry learn promote`: each
entry names the change that learned it, its confidence when promoted, and the
evidence in that record. Implementation and exploration load this file with
the baseline rules. Edit it only through a change record, the way it was
written.

## commit-the-failing-test-first

- **When:** when starting a feature, fix, or refactor
- **Do:** commit the failing test alone before any implementation, then name that commit as red_commit on the verification check that runs it
- **Confidence:** 0.90 (from change learning-instincts, domain testing; evidence: red-green-evidence REV-020, changes/red-green-evidence/06-verification/tests.yml, changes/learning-instincts/06-verification/tests.yml)

## check-the-commit-landed-before-binding-evidence

- **When:** when about to generate or bind evidence to a commit in a repository with a pre-commit hook
- **Do:** confirm HEAD moved after git commit before generating anything that names the commit
- **Confidence:** 0.85 (from change learning-instincts, domain git; evidence: changes/phase-runner/05-implementation/log.md, changes/phase-runner/05-implementation/deviations.md)

## regenerate-evidence-never-annotate

- **When:** when a transcript or evidence file shows the wrong thing because of a harness or script error
- **Do:** fix the harness and regenerate the evidence in full rather than annotating what the wrong run showed
- **Confidence:** 0.85 (from change learning-instincts, domain verification; evidence: changes/lifecycle-tracks/07-evaluation/results.md, changes/red-green-evidence/07-evaluation/results.md, changes/learning-instincts/07-evaluation/results.md)

## measure-staleness-on-the-record-branch

- **When:** when an open record from another branch reads as stale on a branch stacked on it
- **Do:** do not rebind the earlier record to the later commit; the record's own branch is the measure, and the tool now does this
- **Confidence:** 0.80 (from change learning-instincts, domain governance; evidence: changes/phase-runner/05-implementation/deviations.md, test/stacked_branch_test.rb)
