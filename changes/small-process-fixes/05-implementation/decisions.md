# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Summary reader lives in `lib/soft_foundry/change_summary.rb`, not in `snapshot.rb` | Add to `Snapshot` as the plan said | `Snapshot` is built around the gate and the JSON board; the summary must not run the gate and has its own bounded reader | A small new file; `snapshot.rb` untouched |
| A single run that marked a phase blocked exits 2 | Keep the previous exit (0 when the gate does not fail) | A blocked handoff is a warning to the gate, so the run would have looked successful; the parallel path already counts blocked as a failure | `phase run` returns 2 for a blocked result |
| `mark_blocked!` returns a count or nil and raises on failure; the CLI prints `blocked:` or `warn:` | Print from the runner | Keeps the runner free of output and the two run sites sharing one message | One helper in `cli.rb` |
| An access-control glob is "unreadable" when it fails `Declarations.syntax_problems` or has an unclosed `[` or `{` | Require every glob to match a tracked file (the `check` rule) | A glob matching no file today is legitimate for a change that is about to add one; an unclosed bracket can never match | Invalid globs fail visibly (MIT-007); an unmatched but valid glob is `check`'s concern |
| Vocabulary lint reads the `# a \| b` comment on the `type:` and `risk:` lines of the template | Parse a structured field | The template already carries the list as a comment; no template format change | Changing the comment shape needs the lint updated |
| The parity check treats `not_applicable` as a stated value needing a note, like `disabled` | Accept it bare | Matches REQ-013: every check states a value with a note when none is in force | Slightly stricter than `disabled`-only |
