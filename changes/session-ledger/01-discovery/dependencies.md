# Dependencies

## Internal dependencies
`SafeWrite` (settings writes), `Git` (branch and repository root), `ChangeRecord`/`ControlPlane` (change and phase for a branch), `ContentScan::SECRETS` (masking), `Processes`/`Snapshot` (UI).

## External services and libraries
None added. Standard library only (`json`, `securerandom`, `shellwords`, `fileutils`). The agents themselves are external programs whose hook contracts are recorded in `00-intake/assumptions.md`: Claude Code 2.1.293, Codex 0.139.0, Grok 1.0.30.

## Infrastructure dependencies
N/A: no deployed service; the ledger is a local file.
