# Implementation Decisions

See `log.md`'s "Decisions" table.

## Threat consideration for `deep` mode (in lieu of a full adversarial-testing phase)
`deep` mode is the one genuinely new risk surface in this change: it shells out to an external binary. Considered directly, not through a dedicated attack phase, given this change's scope:

- **Command injection**: the prompt is a fixed Ruby constant with no repository content interpolated into it, and it is passed as a separate argv element (`Open3.popen2e(*argv, ...)`), never through a shell string. No injection path exists regardless of what the target repository contains.
- **Symlink/write escape**: the agentic process itself runs with whatever filesystem access `claude` already has when invoked by the operator; this change grants it no new capability beyond what `repository-discovery`'s own `permissions.yml` already allows (`.ai/repository.yml` outside a change context). It is not a new privilege boundary.
- **Hang / resource exhaustion**: bounded by `TIMEOUT_SECONDS` (900s default), with the subprocess killed on timeout rather than left running.
- **Silent partial success**: `run!` checks the target file's mtime before and after, so a `claude` invocation that exits 0 but touches nothing is reported as a failure, not silently treated as success.
- **Not covered**: this reasoning was not adversarially tested by a fresh-context attacking agent, only reasoned through directly. If `deep` mode sees real use, it is a good candidate for a dedicated attack pass later.
