# Example: the thin loop

This is a sketch of what Soft Foundry looks like in an application
repository after `soft-foundry init`. It is not a live change record
(`soft-foundry ci` does not read this directory).

The packaged default track for an application is **iterative**:

1. Person and agent shape the feature in a development environment.
2. Each round is journaled.
3. The person accepts with `change vet`.
4. Implementation and verification produce commit-bound evidence.
5. Review and judgment run in a fresh session (`phase run`) when the
   risk warrants it.
6. `change close` after merge.

Threat modeling, adversarial testing, observability, and FAQ indexing
stay available. They are not required before the first useful change
lands.

## Commands that produced this sketch

```bash
soft-foundry init
git checkout -b change/add-json-flag
soft-foundry change new add-json-flag --title "Add a --json flag"
# …iterate, deploy only to development, append the journal…
soft-foundry change vet add-json-flag --by "Alex"
soft-foundry gate implement
soft-foundry gate verify
soft-foundry phase run review
soft-foundry change close add-json-flag
```

Read `changes/add-json-flag/` next. Compare that with any live record
under this repository's top-level `changes/` directory — those are the
audit log of Soft Foundry itself, not the starting example.
