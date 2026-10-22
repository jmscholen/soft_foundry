# Assumptions

## Explicit assumptions
- Scope is declared in the change record (`metadata.yml`) as path globs; discovery's affected components inform it, but the declaration is explicit and reviewable.
- The shared core is declared in `.ai/repository.yml` (or a policy file) as path globs, and `soft-foundry check` validates it.
- A change with no declared scope is treated as whole-repository scope (today's behaviour).
- The full-suite result is recorded in the verification evidence with the tree hash, command and outcome; tree hash comes from `git rev-parse HEAD^{tree}` of the evidence commit.

## Ambiguities resolved
- "Cache" does not mean Soft Foundry executes the suite; it means a recorded, tree-keyed result later verifies cite. (Resolved from the field report: the suite is the application's, run by the verify session.)
- Split into three stacked changes was chosen by the user.

## Ambiguities that block safe progress
None. Open design questions (scope declaration syntax, where shared core lives, how "alters access control" is computed from a diff) belong to specification and are not blocking.
