# Dependencies

## Internal dependencies
- `Gate`, `ChangeRecord`, `ControlPlane`, `Git`, `Advisory`, `PhaseRunner`, `Check`, `ContentScan` (all in `lib/soft_foundry/`). The eval runner composes them the way the test suite does: a scratch git repository carrying a copy of the control plane, a scaffolded record, and a gate run.
- `test/test_helper.rb` (`FoundryFixture`): the scratch-repository pattern and `complete_phase!`, which the runner reproduces in library code so an installed gem can run evals without the test suite.
- `.ai/skills/*/template/**`: the eval runner fills templates by replacing the placeholder word, as `complete_phase!` does, so a case stays valid when a template gains a section.

## External services and libraries
- Ruby standard library only (`yaml`, `json`, `tmpdir`, `fileutils`, `open3`, `digest`, `securerandom`). No new gem.
- `git` on `PATH` (already required).
- For live evals only: an installed coding shell (`claude`, `codex`, or `grok`) that answers headless prompts, and its login. Not required by `ci`.

## Infrastructure dependencies
N/A. CI (`.github/workflows/ci.yml`) already runs `rake ci`; `ci` gains the deterministic evals. No deployed service.
