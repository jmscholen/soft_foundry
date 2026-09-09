# Ruby Standard

- Prefer idiomatic, readable Ruby over clever or compressed Ruby.
- Use descriptive names and small public APIs.
- Prefer keyword arguments when positional meaning is not obvious; avoid boolean positional arguments.
- Avoid metaprogramming unless it materially reduces complexity and remains understandable to maintainers.
- Do not rescue `Exception`.
- Do not broadly rescue `StandardError` without an explicit handling, reporting, and recovery strategy.
- Keep mutation obvious and localized.
- Prefer Enumerable operations when they improve clarity, not merely brevity.
- Avoid monkey patches unless explicitly approved as a repository convention.
- Respect the repository's configured formatter, linter, Ruby version, and test framework.
