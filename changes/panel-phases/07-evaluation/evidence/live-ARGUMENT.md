# Argument


## claude-1, round 1

I read `claude-1/draft.md` and `grok-1/draft.md`. I'm adopting grok-1's contract as the panel outcome, with two additions and one note on how its evidence was gathered.

**Where we agree**
- The version lives in a `VERSION` file at the checkout root, in the parent of the executed script's `bin/` directory. It is found from the script's location, not the working directory. My draft reached the same choice (my Option A) on the same grounds: release tooling is a non-goal, `lib/` is unused, and a missing or bad data file can give a plain error where a failed `require` would give a load backtrace.
- grok-1's Theory D is right, and I'm dropping my fallback of leaving the location as a non-binding note. Intake asks this phase to settle it, and the missing-file contract differs from the load-error contract. Naming the file is a specification of behavior, not an implementation detail.
- Running `bin/hello` with no arguments never opens `VERSION`. Failures exit 1 with one stderr line and no backtrace. Output is ASCII only and never contains ANSI escapes. An accessibility requirement is included even though `surfaces.accessibility` is false. Standard library only, no network, nothing about privacy or security policies changes, and nothing blocks readiness. My REQ-001..008 and AC-001..007 all fit inside grok-1's REQ-001..011 and AC-001..012, which are stricter: exact stderr strings, a token grammar, a 256-byte cap, and an environment-override check.

**Where I first differed, and now accept grok-1's position**
- *Unknown arguments (grok-1 REQ-005).* My draft kept today's behavior for unknown arguments out of scope, partly because I had not read `bin/hello`. Rejecting them is a behavior break intake did not ask for. Still, grok-1's case holds: once `--version` exists, a typo like `--verison` must not look like a successful greeting. Nothing in the tree calls `bin/hello` with arguments. I accept REQ-005 as an authorized, deliberate break, recorded as such in `specification.md`.
- *Initial token `0.1.0`.* Intake names no number, but an exact expected stdout for the shipped checkout needs one. I accept it as the initial contents, not part of the contract. The maintainer can change the file without changing any requirement.
- *Execute bit (REQ-011).* I checked file metadata only (`ls -l`): `bin/hello` is `-rw-r--r--`, 33 bytes, and `lib/` exists but is empty. Intake states the command as `bin/hello --version`, so that command has to work. REQ-011 is justified.

**Additions I ask for in the final phase files**
1. *Second handoff finding, SPEC-002 (minor).* `.ai/repository.yml` profiles the Soft Foundry gem (`init-command`, APP = `lib/**`, `exe/**`), not this tree. `bin/hello` and a root `VERSION` fall in no path group in `.ai/paths.yml` or in that override. So the `deny_write: ${APP}` rules in the specification, threat-model, and verification skills do not protect the files this change edits. Failure mode: a later phase writes to `bin/hello` or `VERSION` and permission checks raise nothing. Discovery was skipped, so nothing has corrected this. grok-1's draft mentions the stale profile only for policies, not for path groups. Threat modeling and planning should know about it.
2. *Note where the evidence comes from.* grok-1's findings 1–2 come from reading and running `bin/hello`. `bin/` is not in this skill's read set (`${CONTROL_PLANE}`, `${DOCS}`, intake, discovery). The facts are not in dispute and the file mode is visible from metadata. The record should still say they were observed outside the read set, and that verification must confirm the baseline (today's argument handling, mode 0644) independently. The specification should not lean on them as if discovery had produced them.

Neither addition changes a requirement or an acceptance criterion. They are a handoff finding and a sentence in `readiness.md`. Round 2 settles if grok-1 accepts them, or if grok-1 explains why the path-group gap belongs only to discovery.

agree: The specification adopts grok-1's contract (VERSION file beside bin/ holding 0.1.0, exactly --version prints "hello <token>" and exits 0, no-argument greeting never reads VERSION, all other argument lists and bad VERSION states exit 1 with the fixed stderr lines, REQ-001..REQ-011 and AC-001..AC-012), is ready for threat modeling with no blocking unknowns, and records minor handoff findings for the false accessibility surface and for the stale repository profile leaving bin/hello and VERSION outside every path group.

## grok-1, round 1

I read both drafts and claude-1's round 1. The two additions do not change REQ-001 through REQ-011 or AC-001 through AC-012. I accept them, with a tighter failure mode on the path-group finding.

**Where I agree**
- The normative contract is the one in `grok-1/draft.md`: a `VERSION` file beside `bin/`, shipped token `0.1.0`, exactly `--version` prints `hello <token>` and exits 0, the no-argument greeting never opens `VERSION`, and every other argument list and every bad `VERSION` state exits 1 with the fixed stderr lines. Leaving the file-versus-constant choice non-normative would leave two different failure contracts open. Intake asked this phase to settle it.
- Unknown arguments are an authorized break with today's ignore-`ARGV` behavior. The initial token is the shipped file contents, not a format law. The owner execute bit is required because intake names the invocation `bin/hello`.
- Minor finding for the false accessibility surface: `surfaces.accessibility` is false, and the change still adds a line a person reads. REQ-006 stays. Metadata is not edited in this phase.
- Minor finding for the stale profile: `.ai/repository.yml` overrides `APP` to `lib/**` and `exe/**`. `.ai/paths.yml` does not list `bin/**` or a root `VERSION` either. Both files this change edits are outside every path group. Discovery was skipped and did not correct that. It is not a blocking unknown for specification.

**Where I do not take the failure mode as first written**
- "Permission checks raise nothing" is wider than the guard. `.ai/policies/enforcement.yml` checks Edit and Write against the write allowlist and against `deny_write`. Threat modeling, planning, and verification may write only their phase directories, so an edit of `bin/hello` or `VERSION` is still outside those write sets. Implementation may write `${APP}`, `${TESTS}`, `${INFRA}`, and `05-implementation/**`, so an edit of those two paths is outside that allowlist too. The check that does not name them is bash: bash is compared only to deny sets, and `deny_write: ${APP}` does not match `bin/hello` or `VERSION`.
- What settles the wording is that pair of facts in the finding, not a claim that every permission check is silent. Severity stays minor. Planning needs the finding so implementation does not assume `${APP}` covers `bin/hello`.

**Evidence outside the advisory read list**
- I did read and run `bin/hello`. `bin/` is not in this skill's read list, and it is not in `deny_read`. Enforcement treats read lists as advisory context, so the read was not a denied read. Discovery recorded none of this baseline.
- I accept one readiness sentence: the ignored arguments and mode `0644` were observed outside that advisory list, and verification must confirm that baseline itself instead of treating this specification as discovery evidence.
- That sentence does not change a requirement. REQ-011 stands because intake names `bin/hello` as the command. REQ-005 stands because a mistyped flag must not look like a successful greeting.

agree: The specification adopts grok-1's contract (VERSION file beside bin/ holding 0.1.0, exactly --version prints "hello <token>" and exits 0, no-argument greeting never reads VERSION, all other argument lists and bad VERSION states exit 1 with the fixed stderr lines, REQ-001..REQ-011 and AC-001..AC-012), is ready for threat modeling with no blocking unknowns, and records minor handoff findings for the false accessibility surface and for the stale repository profile leaving bin/hello and VERSION outside every path group.
