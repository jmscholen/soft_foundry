# Argument

## claude-1, round 1

I read `panel/grok-1/draft.md` and `panel/claude-1/draft.md`. ARGUMENT.md had no earlier sections.

### Where we already agree

- **Facts.** `bin/hello` ignores argv. It is mode 0644, so direct execution exits 126. `lib/` is empty. Discovery was waived and its files are still templates. `.ai/repository.yml` is the Soft Foundry gem's profile, not evidence about this scratch.
- **Behavior.**
  - No arguments: exactly `hello\n` on stdout, empty stderr, exit 0, and the version source is not needed.
  - Exactly `--version`: `hello <token>\n`, exit 0.
  - The token is resolved from the program's own location, not the working directory.
  - Initial token `0.1.0`.
  - Ruby standard library only, no network, no shell, nothing executed from input.
- **Classification.** An accessibility requirement is owed even though `surfaces.accessibility` is false, and that flag mismatch is a finding. `surfaces.policy: false` is correct, and the token is classified `none`.
- **No blocking unknowns.** Specification is ready.

### Where I change my position

1. **Version source: I accept the root `VERSION` file.** My deciding argument was that `lib/**` is inside implementation's write set and a root `VERSION` is not. On a second look, that argument does not separate the options. `bin/hello` is also outside `${APP}` (`lib/**`, `exe/**` per `.ai/repository.yml`). So the path groups must be corrected or an exception recorded whichever source is chosen. Once that has to happen anyway, adding `VERSION` to the same fix costs nothing. That leaves grok-1's points standing:
   - there is no library or module to attach a constant to;
   - the maintainer named `VERSION` first;
   - a data file is never loaded as code;
   - grok-1 specifies each failure (missing, unreadable, empty, unusable) as a distinct, actionable stderr line instead of a load-error stack trace.

   Grok-1's design is the more complete one.
2. **Other argument lists: I accept a usage error (exit 2, empty stdout, one `hello:` stderr line), checked before `VERSION` is read.** I kept the old ignore-everything behavior only to avoid an unrequested change. Grok-1 is right that the intake promises only the no-argument form, and ignoring argv was never a stated interface. Keeping the old behavior also makes `--version=1.2.3` or `--version extra` silently print `hello`, which looks like success. Since `.ai/rules/errors.md` says failures must be visible, the usage error fits it better.
3. **Token grammar: I accept `[0-9A-Za-z][0-9A-Za-z._+-]{0,63}` over my SemVer-only rule.** Nothing in the intake requires SemVer, and AC-012 (the token `exit` printed literally) depends on the wider grammar.

### Where grok-1's draft must change

1. **Missing finding: implementation cannot write `bin/hello` or `VERSION`.** This is my draft's F1, and grok-1's draft does not mention it. `.ai/skills/implementation/permissions.yml` allows writes to `${APP}`, `${TESTS}` and `${INFRA}` only. `.ai/repository.yml` overrides `APP` to `lib/**` and `exe/**`, and `TESTS` to `test/**`. Neither `bin/**` nor a root `VERSION` is in any group.
   - Failure: implementation edits `bin/hello`, sets its mode to 100755 and creates `VERSION`. The guard (mode `warn`) logs three permission violations, and review flags writes outside the write set. If implementation instead keeps to its write set, REQ-002, REQ-003 and REQ-004 cannot be met.
   - The specification cannot fix this, because `.ai/` is denied to it. It must be a **major** handoff finding, and `readiness.md` must name it, so planning resolves it before implement. The fix is repository-discovery refreshing `paths:`, or a recorded human exception.

   This does not block specification itself.
2. **AC-014 needs a portable verification path (minor).** "A network namespace or firewall that fails the run if a socket is opened" is straightforward on Linux. This worktree is on Darwin, where it needs root or sandbox tooling. To keep it from becoming an untestable criterion at verification, I suggest adding to `then`: "or, where socket isolation is unavailable, inspection of the program shows no socket, HTTP or DNS call". That pairs it with the static check grok-1 already implies in REQ-008.
3. **AC-009's no-read-permission case must say "run as a non-root user" (minor).** Root reads a mode-000 file, so the case would print the version and fail spuriously under a root CI runner.
4. **Coverage gap (minor).** No AC covers the shipped tree's mode. I suggest adding to AC-016's `then`: "`git ls-files -s bin/hello` reports mode 100755". AC-001 covers direct execution only in the working tree, and a commit that loses the bit would pass locally after a `chmod`.

### What would settle it

Grok-1 accepts finding 1 above as a major handoff finding named in readiness. I think findings 2 to 4 are worth taking, but I would not hold agreement on them.

agree: Adopt grok-1's draft (root VERSION file, initial token 0.1.0, exit 2 for any other argument list, exit 1 for version-source failures) as the specification, adding a major handoff finding that bin/hello and VERSION lie outside the implementation write set because .ai/repository.yml overrides APP to lib/** and exe/**.

## grok-1, round 1

I read `panel/claude-1/draft.md`, `panel/grok-1/draft.md`, and claude-1's round 1. I rechecked `.ai/skills/implementation/permissions.yml` and the `paths:` block in `.ai/repository.yml`.

### Where I agree

Claude-1's revised position matches the product contract in my draft: root `VERSION` file, initial token `0.1.0`, no arguments prints `hello` and does not need the file, exactly `--version` prints `hello <token>` and exits 0, any other argument list is exit 2 before the file is read, and a missing or bad version source is exit 1. The token grammar, cwd-independent lookup, stdlib-only constraint, accessibility requirement despite the false flag, and `none` classification of the token are the same.

The write-set finding is real and I missed it. Implementation may write only `${APP}`, `${TESTS}`, and `${INFRA}`. This repository overrides `APP` to `lib/**` and `exe/**` and `TESTS` to `test/**`. Neither `bin/hello` nor a root `VERSION` file is in those groups. The guard mode is `warn`, so an edit is logged rather than refused, and review can still flag it. Keeping inside the write set makes REQ-002, REQ-003, and REQ-004 impossible. A constant in `lib/hello/version.rb` would not remove the problem, because `bin/hello` itself is outside the write set and must change either way. Specification cannot edit `.ai/`. I accept this as a major handoff finding, and `readiness.md` will name it so planning resolves it before implement (refresh `paths:` or record an exception). It does not block specification and it does not move the version source back to a Ruby constant.

I also accept the three minor criterion notes, and they do not change the agreed sentence:

- AC-014's `then` gains a portable alternative: where socket isolation is unavailable, inspection of the program shows no socket, HTTP, or DNS call.
- AC-009's unreadable-file case is run as a non-root user, because root can read a mode-000 file.
- AC-016's `then` includes `git ls-files -s bin/hello` reporting mode `100755`, so a commit that drops the execute bit cannot pass on a working tree that was only chmod'd.

### Where I do not agree

Nothing remains that I would refuse. Claude-1's original constant and preserve-argv positions are withdrawn, and the evidence they gave for withdrawing them is the evidence I would have used.

### What settles it

The sentence below is claude-1's sentence, repeated exactly. The three minor criterion notes above are included when the phase files are written.

agree: Adopt grok-1's draft (root VERSION file, initial token 0.1.0, exit 2 for any other argument list, exit 1 for version-source failures) as the specification, adding a major handoff finding that bin/hello and VERSION lie outside the implementation write set because .ai/repository.yml overrides APP to lib/** and exe/**.

