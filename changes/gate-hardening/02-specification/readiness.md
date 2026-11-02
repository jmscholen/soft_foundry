# Specification Readiness

## Blocking unknowns
None. The eight rows in `01-discovery/unknowns.md` are resolved in this specification as follows: closed and released records skip every new check (REQ-007); parallel sealing is ordered (REQ-005); fixtures that complete phases without committing are the implementation's RED-commit finding (REQ-006, AC-016); the commit message is `Record <slug> <phase id>` (REQ-001); attack cases name threats, not criteria, so coverage counts verify checks and evaluation journeys only (REQ-011); REV-001 is scoped to the recorded `branch_resolved` measure (REQ-020); hook cost is measured at evaluation (REQ-036, AC-052); lineage uses the tip `Scope.tip_for` uses (REQ-009, AC-024).

## Untestable criteria
None. Every criterion is a command or gate run on a fixture with an observable exit code, printed line, file content, or commit. AC-052's accessibility clause is an inspection of output text against REQ-032, as on earlier changes, and its timing clause is a measurement with a stated bound.

## Carried residuals, with reasons
Named here so the judgment can carry them without rediscovering them (REQ-027):
- `scoped-verification` REV-003, a `**`-scoped active sibling claims every path: changing what a scope may claim is a policy decision about `check-sizing.yml`, not a gate fix.
- `phase-lifecycle-controls` REV-008, a kill mid-rename leaves a partial reset without a history entry: needs a journal design; `change close` already fails closed.
- `small-process-fixes` REV-004, a format character in an `access_control` glob: `check` already refuses the character in `.ai/`; the remaining path needs a committer to plant it.
- `small-process-fixes` REV-011, a red commit citing a different test file: cannot be detected structurally without re-running the test at the red commit, which the gate's boundary forbids.
- The inert `transitions`, `rules`, and skill `completion.yml blocking` declarations: making them live or removing them is a design change to the control plane's vocabulary; this change corrects the README's description of what they do (REQ-028).

## Ready for threat modeling and planning
Yes. The functional behaviour is fixed in enough detail that the threat model can enumerate forgeries (executed_by, branch_resolved, criteria_not_covered, a symlinked record, a `--no-verify` commit) and the plan can order the work by RED commits. The specification is on the gated track at high risk; nothing is waived.
