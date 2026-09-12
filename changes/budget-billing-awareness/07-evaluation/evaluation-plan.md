# Evaluation Plan

Walk the maintainer's actual complaint end to end against a real scratch repository carrying this repository's own `.ai/` control plane and the actual CLI executable (a real process with a real, buffered stdout — not a StringIO), with a fake `claude` on `PATH` so `shell claude` genuinely execs into something observable:

1. **Subscription** (no metered credential): `shell claude` says no budget applies and launches; an unrelated `OPENAI_API_KEY` does not change that; `change new` says no budget applies; a $999 recorded entry is shown by `budget status` but never judged against a cap, exit 0.
2. **API key**: `shell claude` announces the policy before launching; `change new` states cap, approval line, interval, and spend so far.
3. **Periodic warning**: $4.00 then $5.50 stays quiet at $9.50; $0.85 more crosses $10 and warns once; `budget status` shows the next boundary.
4. **Adjustable**: `budget threshold` shows the policy default; `25` moves the boundary (no warning at $20, one at $25); `off` silences the interval while the human-approval line still speaks; `default` restores policy; the override file is invisible to `git status`.
5. **Regression**: a title containing ": " round-trips through `metadata.yml`.
6. **Override**: `SOFT_FOUNDRY_BILLING=subscription` beats a present key.

Accessibility is not applicable — a non-interactive CLI with plain-text output.
