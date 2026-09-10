# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Pointer-file block interior that differs from canonical is `conflict`, not `updated` | Replace the region between markers when the file is committed | REQ-007 and DC-5 only define skipped and conflict for pointer files; pointer files are outside the manifest, so ownership of the region cannot be proven | Upgrading the bootstrap text requires a manual edit in every target; recorded as a limitation for learning |
| Manifest entries outside the packaged set are dropped on the next write, with a warning | Preserve them forever | DC-4 says ignored; preserving would warn on every run | One-time warning per stray entry |
| Conflicting `.ai/` files keep their previous manifest hash | Drop them from the manifest | Keeps ownership evidence for a later `--force` and avoids flip-flopping status between runs | Manifest may reference content that no longer matches until the conflict is resolved |
| `updated`/`forced` write the whole file via temp file and rename | Write in place | Atomic replacement means a crash never leaves a truncated managed file (MIT-013) | A transient `*.soft-foundry-tmp` sibling exists during the write |
| Unexpected exceptions inside `init` are wrapped as `InternalError` (exit 4) | Let them surface as generic exit 1 | REQ-011 classifies internal exceptions as Soft Foundry-side | Bugs are reported with upstream guidance instead of looking like user errors |
| `--root` given as a subdirectory is refused with the top-level named | Silently walk up | DC-6; an explicit argument that resolves elsewhere is likely a mistake | Users pass the top-level path or omit `--root` |
| `Git#run` clears `GIT_DIR` and `GIT_WORK_TREE` for every call | Only for root resolution | Simpler and applies MIT-008 to `dirty_paths` and `check-ignore` too | Callers cannot redirect git via environment, which is intended |
| Legacy 0.1.0 `CLAUDE.md` block is recognized by exact text | Treat as bare marker conflict | Every existing user would otherwise see a conflict on upgrade | The legacy text is frozen in `AgentFiles::LEGACY_CLAUDE_BLOCK` |
| Self-install of this repository not performed | Run `init` here to generate `.ai/manifest.yml` | `.ai/manifest.yml` falls under `${CONTROL_PLANE}`, denied to implementation | `doctor` reports the manifest missing on this repository until a later phase or the maintainer runs `init` |
