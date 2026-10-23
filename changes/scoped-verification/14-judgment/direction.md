# Direction from the maintainer for this judgment

Decision recorded 2026-10-23: the maintainer accepts REV-001 (a `git.branch` recorded before the branch exists and created later at the phases-complete commit, indistinguishable from a legitimately stacked branch) as a residual risk, instead of redesigning how stacked changes are measured. Reasoning: exploiting it needs the record's own author to set `git.branch`, and that author already controls the evidence the gate reads; the gate checks structure, not truth. Three fix attempts moved the hole without closing it. A full close means changing how stacked changes behave for adopters, which is a separate change.

Also accepted: REV-003 (an active `**` sibling, named by an advisory) and the minor items REV-004 and REV-006 (a malformed `git:` value crashes the gate with a Ruby error; a stack cut exactly from the evidence tip stales the lower record). The shipped README now states these limits.

REV-002: the maintainer decided that a path claimed by another active record's scope does not raise this record's verify size. REQ-009's locked text is superseded for claimed paths; the shipped policy and README were corrected.

Principle: Soft Foundry applying its process to itself is separate from the process it ships. Judge the shipped intent on its own terms. Accessibility applies to the new CLI and browser output (the review found it conforming); the remaining accessibility advisory is bookkeeping (REQ-021 and REQ-022 are not tagged `category: accessibility`) and is not a risk to the change.

Weigh these as the maintainer's recorded decisions; the judgment is still yours.
