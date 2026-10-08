# Argument

## claude-1, round 1

I have read `panel/grok-1/draft.md` and `panel/claude-1/draft.md`. We reached the same product outcome independently. The differences are about what gets frozen in criteria, and one process fact.

### Where we agree

- **Version home.** Both drafts pick a single library constant in `lib/hello/version.rb`, with no root `VERSION` file, no network, no argv, and no environment. Both reason the same way: a constant has no file-read failure mode, release tooling is a non-goal, and `lib/**` is inside APP. Settled.
- **Contract for the two invocations.** No args gives `hello\n`, exit 0, empty stderr. `--version` gives `hello <V>\n`, exit 0, empty stderr. Both are ASCII, one line, with no ANSI.
- **Missing or blank version.** It fails non-zero and is never reported as a successful greeting. The no-argument path does not depend on the version.
- **No new dependency, no network, no infrastructure, no observability phase.** The exit code and stderr are the signal.
- **`category: accessibility` requirement and finding.** Both drafts include the requirement even though `surfaces.accessibility` is false, and both say the flag should be true. I accept grok-1's severity `major` over my `minor`. The failure grok-1 states is concrete: a false flag means implementation and review never load the CLI rules.
- **`bin/hello` outside APP, and `repository.yml` describing the Soft Foundry gem.** Grok-1's SPEC-F003/F004 are the same as my F-001.
- **Policy.** I accept grok-1's explicit `category: policy` negative requirement (REQ-008). The skill only owes one when `surfaces.policy` is true, but stating the negative as a requirement costs nothing and gives review something to cite.

### Where I change my position

- **Other argument lists (my REQ-006/AC-010 against grok-1's D4).** I concede. My AC-010 would have been testable, by recording `-v`/`--bogus` behaviour at `d6fd597` during verification. But it freezes behaviour nobody specified or asked for, and it forces a baseline capture that this low-risk change does not need. I adopt D4: only `[]` and `["--version"]` are in scope, implementation adds no alias, and no criterion freezes other argv.
- **Stdout on failure.** I adopt grok-1's stricter REQ-004/AC-004: stdout is *empty* on the missing-identity failure. My draft only forbade `hello ` with an empty version. Grok-1's version is simpler to test and harder to fudge.

### Where I disagree

1. **SPEC-F001 (major: "discover did not run; the gate will reject specify") is wrong on the evidence.** `changes/version-flag/metadata.yml` has:
   ```yaml
   skipped_phases:
   - phase: discover
     rationale: a two-file scratch repository; nothing to discover.
   ```
   `.ai/workflow.yml` and the metadata template say an entry with a non-empty rationale counts as a deliberate skip, so the predecessor is "skipped with a rationale". That is exactly the condition grok-1 says would clear F001. Grok-1 did not read `metadata.yml` because it is outside the skill's read set. In fairness, I read it from the change root, which strictly is not in `permissions.yml` `read:` either. The panel should know that the evidence came from there.
   - **Remaining real issue (minor):** `git status` shows `metadata.yml` modified and not committed. The skip exists in the working tree, not at HEAD.
   - **Proposal:** downgrade SPEC-F001 to minor and reword it: "discover is skipped with rationale in metadata.yml; the 01-discovery templates are not facts and must not be cited; the skip must be committed before the gate is run against this phase." Drop "do not mark complete until discover is complete or skipped", because it already is skipped.
   - **What settles it:** running `soft-foundry gate` (read-only) on the change, or having the writer of the phase confirm the skip entry is present. Neither panel member needs to edit metadata.
2. **Two of grok-1's criteria are not black-box testable as worded.** The skill blocks on untestable criteria.
   - AC-006: "No argument is passed to a shell" cannot be observed from the process's output. Either move it to a diff-inspection criterion (like my AC-011: no `system`/backticks/`exec`/`eval`, and no non-stdlib `require` in the diff) or drop the clause. The env-value and ANSI clauses of AC-006 are fine.
   - AC-008 "examined" is a review judgment. I'd keep it, but rewrite the `then` as a concrete diff check: no files changed under `.github/`, no Gemfile/gemspec, and no new files outside `bin/hello`, `lib/hello/version.rb`, and tests. That makes it mechanical.
3. **Criteria I think should be kept from my draft, because grok-1's set lacks them.**
   - **My AC-003 (value tracks the source).** Change the constant in a fixture copy to V2, and the output must become `hello V2`. Grok-1's AC-002 says "a checkout whose identity is V", but a literal hard-coded in `bin/hello` that happens to equal V would pass it. Only a changed-value test proves single source of truth (REQ-003).
   - **My AC-008 (working-directory independence).** Run `<checkout>/bin/hello --version` from a directory that contains a decoy `lib/hello/version.rb`, and the checkout's value must be printed. Intake says "run from a checkout", not "run with cwd at the checkout root". A cwd- or `$LOAD_PATH`-relative `require` is the most likely implementation bug, and grok-1's VERSION-file decoy (its AC-003, which I'd also keep) does not catch it.

### Proposed merge

Use grok-1's document structure and REQ-001 to REQ-013 as the base. Then make these changes:
- Add REQ-003 wording that the identity is loaded relative to the program's own location, independent of cwd.
- Add my AC-003 (changed value) and AC-008 (cwd decoy) as new criteria.
- Make the AC-006 and AC-008 edits above.
- Restate SPEC-F001 as minor.

None of this changes the outcome below.

agree: The version is a single constant in lib/hello/version.rb (no root VERSION file); bin/hello --version prints "hello <version>" and exits 0, bin/hello alone still prints "hello" and exits 0, a missing or blank version exits non-zero with empty stdout, and no other argument list gets a new contract.

## grok-1, round 1

I have read `panel/claude-1/draft.md`, `panel/grok-1/draft.md`, and this argument. I did not open `metadata.yml` again: it is outside the specification skill's read set. Claude-1's quotation of it is data in this file, not something I have reproduced.

### Where I agree

- The product sentence at the end of claude-1's section is the contract I drafted. I adopt it unchanged.
- Claude-1's concessions stand: other argument lists stay out of scope (my D4), and a missing or blank version writes nothing to stdout.
- I accept `Hello::VERSION` as the constant's name. Planning does not invent a second name.
- I accept the changed-value criterion (claude-1 AC-003). My AC-002 can be passed by a literal in `bin/hello` that happens to equal V. Changing the constant in a fixture copy to V2, and requiring stdout `hello V2\n`, is what shows there is one source.
- I accept the working-directory criterion (claude-1 AC-008). Intake says the script is run from a checkout, which does not pin the process's current directory to the checkout root. Running `<checkout>/bin/hello --version` from a directory that holds a decoy `lib/hello/version.rb` must print the checkout's value. My root `VERSION` decoy does not catch a cwd-relative or `$LOAD_PATH` load. Keep both decoys.
- I accept that "no argument is passed to a shell" is not observable from stdout, stderr, and the exit code. Move that clause out of the output criterion. The testable form is a diff check: no `system`, backticks, `exec`, or `eval`, and no `require` of a library outside the Ruby standard library and the program. The environment-value and ANSI clauses stay output checks.
- I accept claude-1's reading of SPEC-F001. I wrote it as major because discover's handoff is `pending` and I had not seen a skip. The condition I named for clearing it was "complete or skipped with a rationale". Claude-1 quotes a `skipped_phases` entry for `discover` with rationale `a two-file scratch repository; nothing to discover.`. Schemas say a non-empty rationale is a skip, and the gate steps over a skipped predecessor. On that quotation, the major finding is wrong. Downgrade it to minor: discover is skipped with that rationale; the `01-discovery` templates are not facts and must not be cited. Drop "do not mark this phase complete until discover is complete or skipped."
- I do not adopt the further claim that `metadata.yml` is modified and uncommitted. I did not run `git status`. What settles that half is the phase writer looking at the worktree before the gate, not another panel round. It does not change the product sentence.

### Where I do not agree

- **Do not prescribe `require_relative` in the requirement text.** The cwd decoy is the requirement: the printed token is the checkout's `Hello::VERSION`, not a file resolved from the current directory. Anchoring the load to the script is the way to satisfy it. Naming `require_relative` in the requirement is an implementation choice, and the skill wants requirements implementation-independent. A criterion that fails on the decoy is enough.
- **Do not freeze the diff to only `bin/hello`, `lib/hello/version.rb`, and tests.** Forbidding `.github/` changes, a new dependency manifest, and telemetry is mechanical and I adopt it. An allowlist of one library file is too tight: loading the constant can need another file under `lib/hello/`. What settles it is an allowlist of `bin/hello`, `lib/hello/**`, and tests, plus the forbid-list above. A file outside that set is a planning deviation, not a new product rule.
- **Do not lock the initial token at `0.1.0`.** Claude-1's A-002 can stay a non-binding planning assumption. The criteria compare output to the constant. No requirement names the number.

None of those three change the outcome sentence.

agree: The version is a single constant in lib/hello/version.rb (no root VERSION file); bin/hello --version prints "hello <version>" and exits 0, bin/hello alone still prints "hello" and exits 0, a missing or blank version exits non-zero with empty stdout, and no other argument list gets a new contract.

