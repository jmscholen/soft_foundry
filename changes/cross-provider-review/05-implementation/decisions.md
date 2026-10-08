# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| The preference lives in each skill's `skill.yml` | A field on the profile | Profiles are shared (review uses `reasoning_high`, which other skills use too) | Any skill can opt in; `check` lints the phase names |
| `resolved_model.provider` first, then the runner's `executed_by.shell` | The shell only | A shell can be pointed at another provider; the agent records what it used | The provider is agent-written; a review that misstates it silences the advisory (residual) |
| `PhaseProvider` as its own module | Methods on `PhaseRunner` | The advisory cannot load the runner without a cycle | `PhaseRunner.provider_of` delegates to it |
| Unknown implementation provider: claude plus a warning | Pick any other shell | "Different" cannot be judged without knowing the first | The person is told to name one with `--shell` |
| The `shell:` line on standard output, the warning on standard error | Both on one stream | Matches the runner's other lines (status on stdout, `! warn` on stderr) | Each line keeps a status word |
