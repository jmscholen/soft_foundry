# Proposed Rule Changes

Proposals are not self-applied. Each becomes a governance change against `.ai/` that follows the standard lifecycle.

| Proposal | Target file | Motivating finding | Draft wording |
| --- | --- | --- | --- |
| Promote `commit-the-failing-test-first` (0.90) | `.ai/rules/learned.md` via `soft-foundry learn promote` | red-green-evidence REV-020 | As in `instincts.yml`; the promote command writes the section |
| Promote `check-the-commit-landed-before-binding-evidence` (0.85) | `.ai/rules/learned.md` via `learn promote` | phase-runner deviations | As in `instincts.yml` |
| Promote `regenerate-evidence-never-annotate` (0.85) | `.ai/rules/learned.md` via `learn promote` | three evaluation results files | As in `instincts.yml` |
| Promote `measure-staleness-on-the-record-branch` (0.80) | `.ai/rules/learned.md` via `learn promote` | phase-runner deviation 1 | As in `instincts.yml` |
| A RED-commit line in the implementation log template | `.ai/skills/implementation/template/log.md` | red-green-evidence REV-020 | "## RED commit\nTBD (the commit in which the failing test was added alone)" |
