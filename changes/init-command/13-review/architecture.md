# Architecture Review

## Scope reviewed
Module boundaries and dependency direction across `lib/soft_foundry/{installer,installer/source,manifest,agent_files,safe_write,git,onboarding,provider,providers,check,control_plane,gate,errors,cli}.rb`, checked against `.ai/rules/architecture.md` and `.ai/rules/general.md`.

## Findings

### Layering and dependency direction — conforms
- `Installer#plan` is pure and delivery-mechanism-free: it takes no `$stdout`/`$stderr` and returns a `Plan` value object; `CLI#init` is the only place that prints it. This satisfies "domain behavior should not depend directly on delivery mechanisms."
- Dependency direction is one-way and acyclic: `cli.rb` → `installer.rb` → `{git, manifest, agent_files, installer/source, safe_write}` → `errors.rb`. No file under `installer*`, `manifest.rb`, `agent_files.rb`, `git.rb`, `safe_write.rb`, or `provider.rb` requires `cli.rb` or `onboarding.rb` back. Verified by reading every `require`/`require_relative` line in `lib/soft_foundry/*.rb` and `lib/soft_foundry/installer/*.rb`; no cycle exists.
- External services are isolated: `Git` wraps the `git` CLI behind five narrow methods (`repository?`, `head_sha`, `branch`, `toplevel`, `ignored?`, `commit?`, `dirty_paths`, `changed_since`); `Provider` wraps `Net::HTTP` behind `#discover`. Both are natural seams for testing (confirmed: `test/` stubs `Git`/`Provider` rather than shelling out or hitting the network in most tests).
- `SafeWrite` is a single, reused primitive for every filesystem write (`Installer#atomic_write`, `Onboarding#write_runtime`, `Installer#with_lock`'s lock-file open); there is exactly one place that decides how a write is made safe. Good cohesion, no duplicated unsafe-write logic anywhere in the codebase (`grep -rn "File.write\|File.open.*CREAT" lib/` shows only `SafeWrite`'s own calls and the lock file, which is deliberately excluded from `SafeWrite.write` because it must stay open for `flock`).

### New abstractions — proportionate, not speculative
- `Installer::Source` (canonical-set reader), `Manifest` (ownership ledger), `AgentFiles` (marker-block owner), `SafeWrite` (write primitive) are each a single demonstrated concern from the specification (REQ-002/003, REQ-004, REQ-007, REQ-013). None anticipates unbuilt future needs; `Data.define` value objects (`Action`, `Plan`, `Entry`, `Plan` in `AgentFiles`) are minimal and immutable, consistent with "prefer composition... new abstractions must solve a demonstrated problem."

### Cross-cutting concern ownership
- Error classification (target-side vs Soft-Foundry-side) is centralized in `CLI#run`'s two-branch rescue and `Installer#write`'s wrapping of `SystemCallError`/`IOError`/`TargetError`. One place decides exit codes (`EXIT_TARGET`/`EXIT_CONFLICTS`/`EXIT_INTERNAL`). This is a good example of explicit, non-duplicated ownership of a cross-cutting concern (error classification), satisfying architecture.md.

### Architectural gap surfaced by this change: no owner for "packaged, self-referential" files
The specification and plan require two files that are simultaneously (a) part of the canonical package this repository ships to every other repository, and (b) files that must exist, correctly formed, inside this repository itself for the feature to be exercisable/dogfoodable and for `gem build` to succeed:
- `.ai/templates/repository.yml` — required by `Installer::Source::REQUIRED`, i.e. `init` cannot function for any target without it existing in the package.
- `AGENTS.md`'s begin/end markers — required by `Installer::Source#agents_interior`, which reads *this repository's own* `AGENTS.md` to extract the block every target's `AGENTS.md` receives.

Neither file falls under any existing skill's write permissions (`.ai/templates/repository.yml` is under `${CONTROL_PLANE}`, which every skill except repository-discovery denies, and discovery's own `permissions.yml`/`.ai/README.md` scope its `.ai/` write to `repository.yml` only, not `templates/repository.yml`; `AGENTS.md` is in no path group at all — it is not `${APP}`, `${DOCS}`, or `${CONTROL_PLANE}`). This is a structural gap, not a mistake specific to this change: the permission model assumes a clean separation between "this repository's own control plane" and "application/test/infra code," but has no lane for "content this repository authors as a vendor and also consumes as a self-hosted instance of its own product." Implementation's deviations (a) and (b) are a symptom of this gap, not its cause. See `05-implementation/deviations.md` and the adjudication in `consolidated.md`.

**Recommendation for learning (non-blocking):** either extend repository-discovery's write permission to explicitly include `.ai/templates/repository.yml` (it already owns the sibling `.ai/repository.yml` and is the natural steward of "the unassessed shape of the evidence file"), or introduce a narrow, explicitly-scoped exception in policy for these two self-referential paths, so future edits to the packaged template or the marker block do not have to repeat this deviation-and-review cycle.

## Conformance
**Conforms**, with one structural gap in the permission model (not in the implementation itself) documented above and carried into `consolidated.md` as a non-blocking recommendation for governance follow-up.
