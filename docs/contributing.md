# Contributing to Soft Foundry

This repository is itself governed by Soft Foundry. Product code lives in
`lib/` and `exe/`. `.ai/` is the control plane shipped to adopters.
`changes/` is the audit log of work already done on Soft Foundry — not
the first place to learn the tool. A five-minute walkthrough of the
intended adopter loop is in `examples/tiny-app/`.

## Minimum context for an agent

1. `AGENTS.md`
2. `.ai/workflow.yml` and `.ai/README.md`
3. The current change's `changes/<slug>/metadata.yml`, if one exists
4. Only the current phase skill under `.ai/skills/<name>/`

Do not load closed records, `.ai/harness-evals/`, or other skills'
templates unless the current phase names them.

## Working on this repository

```bash
git checkout -b change/<slug>
bundle exec ruby -Ilib exe/soft-foundry change new <slug> --title "..." --track gated
bundle exec rake test
bundle exec ruby -Ilib exe/soft-foundry check
```

This repository's default track is `gated`. Application repositories
installed by `soft-foundry init` get `iterative` as their packaged
default; `high` risk still forces `gated`.

If repository instructions are ambiguous, contradictory, or prevent safe
implementation, document that in the change record rather than inventing
workflow semantics.

## Tests

```bash
bundle exec rake test
bundle exec rake ci
```

Set `LANG=C` locally if you touch file reads. Control-plane files may
contain non-ASCII text; reads must declare UTF-8.
