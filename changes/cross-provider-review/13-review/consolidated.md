# Consolidated Review

Reviewed at `2c06a8e9581c4a956abcb11a03168c11ed8dace3`. Library, tests, README, and `.ai/` match the verified commit `a963a27e4fc34e5200aa212bbc9d51d67e293cd1`.

Rules applied: baseline `general` and `architecture`; `ruby`, `testing`, `security`, `errors`, `git`, and `dependencies` from the repository profile (Ruby, Minitest, no new dependency, no database, no Rails); `learned` (failing tests committed at `eb3ace3`, `e62bc6e`, and `b4dd692` before the fixes; evidence after REM-002 regenerated rather than annotated). No infrastructure-as-code tool. Accessibility and policy conformance are in their own files. Discovery was skipped for this change; the rule set is the profile's, not a fresh discovery.

## Functional

Conforms. REQ-XP-001 through REQ-XP-007 hold. REV-FUN-001 does not reproduce: with implementation on anthropic, remediation unrecorded, and claude, codex, and grok installed, `phase run review` starts codex and the warning names the missing provider. An unrecognized provider falls back to the recorded shell. The RED-test setup fix and the grok usage line are approved.

## Architecture

Conforms. `PhaseProvider` exists so the advisory does not load the runner. The preference is on the two skills, not on the shared profile. Control-plane and README writes outside the implementation write set are accepted: the requirements demand them, and the diff is only those edits.

## Security

Conforms. The launched executable is an allowlisted shell, and the raw provider string is not interpolated into the command or the message. The advisory-silencing residual and the structural `failure: n/a` residual are the ones attack recorded.

## Accessibility

Conforms. Declared surface. The new lines use the prefix `shell:` or the word `warn`, are ASCII, do not prompt, and do not depend on color or width. No finding. The skipped specification phase will still draw the go-live advisory that no accessibility requirement was recorded. That advisory is about the skip, not about this review.

## Policy conformance

N/A. `surfaces.policy` is false. Privacy, security, and terms are NOT_APPLICABLE in `.ai/repository.yml`. Nothing new is collected, shared, or retained. No policy text change is owed. No human decision is requested.

## Infrastructure

N/A. No infrastructure-as-code tool is recorded, and the diff touches none.

## Operations

Conforms for a library with no deployed service. The `shell:` line, the warning, the exit status, and the same-provider advisory are the operator surface. The observability phase has not run and is optional.

## Blocking findings

None.

## Residual concerns

- `failure: n/a` passes `findings explained`. The intake says the check is structural. ATTACK-001 recorded it. A non-hash entry in `findings` is ignored by the same check (probe: a string passes with "no findings above minor"). The template and the schema require a hash; an ill-formed entry is also invisible to a reader that expects `id` and `severity`. Not filed: it is outside the structure the requirement checks, next to `n/a`.
- A handoff that writes a recognized provider other than the shell that ran silences the advisory and steers `default_shell`. ATTACK-002 and the implementation decision recorded it. A blank provider still falls back to the shell, and the advisory still fires.
- On this machine the default for an anthropic implementation is codex, whose login has expired (EVAL-OBS-001). The intake non-goal stands: `--shell grok` is how this review was run.
- When the only installed shell is already on a known provider, and another named phase's provider is unrecorded, the warning says no other provider's shell is installed and does not also name the unrecorded phase. The shell chosen is the one REQ-XP-003 requires. Not filed.
- User-documentation, FAQ index, and observability phases are still pending. README covers REQ-XP-007. Those phases are optional; this review did not fill them.

## Unresolved findings

None.
