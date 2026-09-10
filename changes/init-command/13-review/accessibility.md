# Accessibility Review

## Scope reviewed
`soft-foundry` is a non-interactive command-line tool; there is no GUI, no rendered markup, and no visual layout to review under conventional (e.g. WCAG) accessibility criteria. Accessibility here is scoped to REQ-014 ("init is non-interactive and its output conveys every outcome with a word, readable without color or Unicode symbols... Agents, CI logs, and assistive technology consume the output") and the general principle that CLI output must be legible to screen readers, plain-text CI logs, and terminals without Unicode/color support.

## Findings

### `init` output — conforms to REQ-014
- Every status is a plain ASCII word: `created`, `updated`, `skipped`, `conflict`, `forced` (`Installer::STATUSES`), plus `check: ok` / `check: failed`, `conflicts:`, `next:`, `summary:`, `root:`, `mode:`. None of these lines use ANSI color codes (confirmed: no escape-sequence emission anywhere in `cli.rb`, `installer.rb`, or `onboarding.rb` — `grep -rn "\\e\[\|\\033\[" lib/` returns nothing) and none depend on a Unicode glyph to convey meaning.
- AC-016 (locked acceptance criterion) — "the output is stripped of non-ASCII characters... every file's status is still identifiable by its status word" — is exercised by an automated test (`test_clean_install_installs_canonical_set_and_manifest`, tagged) and was independently reconfirmed live in `06-verification` (check 9). I additionally spot-checked by reading every `@out.puts` call reachable from `CLI#init`: none interpolate a non-ASCII character into a status or summary line.
- `--root` and other error paths (`resolve_root`, `option`) raise plain-English `TargetError` messages with no glyphs.

### `doctor` and `check` — not covered by REQ-014's literal scope, minor inconsistency noted
- `CLI#doctor` (`lib/soft_foundry/cli.rb:183-197`) prints `✓`/`✗` before each check name; `CLI#check` (`lib/soft_foundry/cli.rb:199-205`) prints `✓`/`✗`/`!` similarly. REQ-014's statement is explicitly scoped to `init` ("init is non-interactive..."), so this is not a requirement violation. However, in both cases the glyph is always paired with a descriptive name or message (e.g. `✓ git repository`, `✗ .ai/manifest.yml`), so no information is glyph-only — a screen reader or `sed 's/[^ -~]//g'` pass still leaves the check name and pass/fail is still inferable from context (though less crisply than `init`'s literal `pass`/`fail` words would be, since `✓`/`✗` collapse to nothing once non-ASCII is stripped, leaving only the name with no explicit status word). This is the one place in the CLI's output surface that is meaningfully weaker than `init`'s own standard.
- `Gate#print_result`/`CLI#print_result` (`cli.rb:266-272`) similarly map outcomes to `✓ ✗ ! -` glyphs with a text detail alongside; same characteristic.

### Non-interactivity
- `init` takes no interactive prompts; all behavior is flag-driven (`--dry-run`, `--force`, `--no-onboard`, `--root`, `--allow-non-git`), consistent with REQ-014's "non-interactive" requirement and confirmed by reading `CLI#init`: no `gets`/`$stdin` read anywhere in the `init` path.

## Findings table
| ID | Severity | Location | Finding | Rule or requirement |
| --- | --- | --- | --- | --- |
| REV-007 | info | `lib/soft_foundry/cli.rb:183-197`, `199-205`, `266-272` | `doctor`/`check`/`gate` output uses `✓`/`✗`/`!`/`-` glyphs which, unlike `init`'s plain-word statuses, convey pass/fail only via a symbol that disappears under non-ASCII stripping (the paired name/message remains, but an explicit status word does not). Not a REQ-014 violation (scoped to `init`); worth a documentation note or a future consistency pass. | REQ-014 (non-blocking, informational) |

## Conformance
**Conforms.** REQ-014 is satisfied for `init`, the command it governs. The `doctor`/`check`/`gate` glyph usage is outside REQ-014's literal scope and does not lose information (a name/message always accompanies the glyph), so it is recorded as an informational observation rather than a nonconformance.
