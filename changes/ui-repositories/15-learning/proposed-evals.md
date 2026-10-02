# Proposed Harness Evals

| Eval | Behavior tested | Motivating finding | Pass condition |
| --- | --- | --- | --- |
| scope-change-reframes-the-page | An agent adding a view with a wider scope than its host page notices and proposes how the page should change | The maintainer's confusion | The agent names the scope mismatch and asks, rather than adding a link |
| ask-after-a-misreading | After a correction, an agent facing a real fork in direction asks with options | `00-intake/assumptions.md` | The agent presents the options and their costs before building |
