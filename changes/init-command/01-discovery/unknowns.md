# Unknowns

| Unknown | Impact if wrong | How to resolve | Blocking? |
| --- | --- | --- | --- |
| How to tell a canonical `.ai/` file from a user-edited one on a second run | Idempotency and conflict reporting cannot be implemented reliably | Specification decides: install manifest with SHA-256 per file under `.ai/` (recommended) versus byte comparison against the packaged copy | no |
| Whether `.ai/harness-evals/` and `.ai/repository.yml` should be installed into targets | Shipping this repository's assessment or eval material into user repositories | Specification decides: install an unassessed `repository.yml`; install `harness-evals/README.md` only | no |
| Name and default of the conflict strategy option | Users may overwrite their own edits, or never be able to accept upstream updates | Specification: default `report`, opt-in `--force` or `--accept-upstream` | no |
| When `docs/user/` scaffolding is appropriate | Unwanted directories in repositories with their own docs layout | Specification: create only when `docs/` is absent or `docs/user/` exists | no |
| Minimum Ruby version | Gem installs on 3.1 and fails at load with `Data.define` | Planning: raise `required_ruby_version` to 3.2 or drop `Data.define`; a README deviation is recorded either way | no |
| Whether `init` should refuse a dirty worktree | Users cannot separate install diffs from their own work | Specification: warn, do not refuse; report every file | no |
| Behavior when the target root is a git worktree or submodule | Root detection may pick the wrong directory | Planning: use `git rev-parse --show-toplevel`, test with a worktree | no |

No unknown blocks specification. Each is a decision the specification or plan phase owns.
