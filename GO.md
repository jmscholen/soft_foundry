# Soft Foundry — Go port

This branch replaces the Ruby gem runtime with a static Go CLI.

The constitution still lives in `.ai/`, `AGENTS.md`, and `changes/`. Those
are data. The process that installs, lints, gates, and guards them is Go.

## Why

The product is a repo-native control plane that must run as a pre-commit
hook and a PreToolUse guard in arbitrary application repositories. A
single static binary does not require MRI on the target machine.

## Build

```bash
go test ./...
go build -o bin/soft-foundry ./cmd/soft-foundry
./bin/soft-foundry version
```

Install:

```bash
go install github.com/jmscholen/soft_foundry/cmd/soft-foundry@go
```

Or from this checkout:

```bash
go build -o bin/soft-foundry ./cmd/soft-foundry
export PATH="$PWD/bin:$PATH"
```

## Port coverage

Implemented:

- `version`, `help`
- `init` / `onboard` (copies `.ai` from the source tree; writes runtime inventory)
- `doctor`, `check`, `ci`
- `change new|status|list|vet|reopen|close`
- `gate` / `gate all`
- `hooks install|uninstall` (`--claude`, `--codex`, `--local`)
- `guard` (stdin JSON, warn/block/off)
- `scan`
- `phase run --dry-run`
- `shell`

Deferred (Ruby still documents the intended semantics):

- full installer conflict/force matrix and packaged gem source
- deep maturity assessment via `claude`
- live provider model listing
- budget / billing notices
- `update` gem install path
- `learn promote` writing `learned.md`
- PR discharge comments
- red/green commit evidence and specification-lock extras

Those can land as follow-up commits on this branch without changing the
command surface.

The Ruby tree under `lib/` and `exe/` is kept on this branch as a
reference implementation until the remaining commands are ported.
