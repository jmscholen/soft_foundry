# Architecture Review

## Scope reviewed
The updater's seams.

## Findings
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-006 | info | `Updater` | HTTP, downloader, runner, and release are injectable; `parse_release` is a pure function. The CLI contract (`check`, `install!`) is unchanged, so the existing CLI tests pass unmodified. | Testability |
| REV-007 | minor | `Updater#real_install` | Fetches the release again when `install!` is called without a prior `check` in the same object; the CLI always checks first, so this is a second request only in the general case. | Simplicity |

## Conformance
Conforms.
