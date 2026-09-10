# Dependencies

## Internal dependencies
- `Installer` (new) depends on `ControlPlane` for the canonical `.ai/` location inside the installed gem, on `Git` for target-root detection, and on `AgentFiles` and `Onboarding` for the existing adapter behavior.
- `Check` is the post-install validator and depends only on the installed `.ai/`.
- `Gate` and `ChangeRecord` are untouched by this change.

## External services and libraries
- Ruby standard library only: `fileutils`, `yaml`, `digest` (for install manifests), `open3`, `net/http`, `json`. No new gems are needed; `rules/dependencies.md` prefers this.
- RubyGems packaging determines which canonical files exist at install time; `Gem.loaded_specs` or `File.expand_path("../..", __dir__)` locates them.
- Provider HTTP APIs (OpenAI, Anthropic, xAI) are reached only by `onboard`, which `init` runs last; they must keep working unchanged.

## Infrastructure dependencies
N/A. GitHub Actions runs `rake test` and `rake ci`; no deployed infrastructure.
