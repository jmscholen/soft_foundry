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

## exempt-closed-evidence-in-policy-not-by-editing-it

- **When:** when a scan flags something in a closed record's commit-bound evidence that is legitimately there
- **Do:** add a narrow allowlist entry with the paths, the kind, a substring, and a reason in policy; never edit the evidence
- **Confidence:** 0.85 (from change control-plane-scan, domain governance; evidence: .ai/policies/content-scan.yml, changes/control-plane-scan/00-intake/assumptions.md)

## sanitize-transcripts-before-they-become-evidence

- **When:** when an evaluation journey deliberately writes an attack, a secret shape, or an invisible character and its output is captured as evidence
- **Do:** have the harness render invisible characters as code points and mask secret shapes before the output reaches the transcript, so the evidence describes the attack without containing it
- **Confidence:** 0.85 (from change control-plane-scan, domain verification; evidence: changes/control-plane-scan/07-evaluation/results.md, control-plane-scan REV-005)
