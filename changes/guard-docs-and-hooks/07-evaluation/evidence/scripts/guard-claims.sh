#!/bin/bash
# EVAL-004 (REQ-GDH-002): every checkable claim in the header of
# .ai/policies/enforcement.yml exercised against `soft-foundry guard` from
# this checkout's library, in a scratch repository under the system temp
# directory. Nothing in this repository is written; the scratch repository's
# guard configuration is the subject under test. Run as:
#   bash changes/guard-docs-and-hooks/07-evaluation/evidence/scripts/guard-claims.sh "$(mktemp -d)"
set -u
REPO=$(cd "$(dirname "$0")/../../../../.." && pwd)
S=$1; A=$S/app; H=$S/home; mkdir -p "$A" "$H"
SF="ruby -I$REPO/lib $REPO/exe/soft-foundry"
clean() { env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$H" TMPDIR="$S" LANG=C.UTF-8 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 "$@"; }
sf() { clean $SF "$@"; }
pass=0; bad=0
# g <0|2> <label> <json payload> [NAME=VALUE ...]: feed one hook payload to the guard and compare the exit code.
g() { exp=$1; label=$2; json=$3; shift 3
  out=$(printf '%s' "$json" | clean env "$@" $SF guard 2>&1); rc=$?
  if [ "$rc" = "$exp" ]; then st=ok; pass=$((pass+1)); else st=UNEXPECTED; bad=$((bad+1)); fi
  printf '%-10s rc=%s expect=%s | %s\n' "$st" "$rc" "$exp" "$label"
  [ -n "$out" ] && printf '      %s\n' "$(printf '%s' "$out" | head -1 | cut -c1-230)"; }
# ga <0|2> <label> [NAME=VALUE ...]: the post-call check.
ga() { exp=$1; label=$2; shift 2
  out=$(printf '{"tool_name":"Bash","tool_input":{"command":"echo hi"}}' | clean env "$@" $SF guard --after 2>&1); rc=$?
  if [ "$rc" = "$exp" ]; then st=ok; pass=$((pass+1)); else st=UNEXPECTED; bad=$((bad+1)); fi
  printf '%-10s rc=%s expect=%s | %s\n' "$st" "$rc" "$exp" "$label"
  [ -n "$out" ] && printf '      %s\n' "$(printf '%s' "$out" | head -1 | cut -c1-230)"; }
# a <label> <condition...>: a file-state assertion.
a() { label=$1; shift; if "$@"; then echo "ok         | $label"; pass=$((pass+1)); else echo "UNEXPECTED | $label"; bad=$((bad+1)); fi; }
w() { printf '{"tool_name":"%s","tool_input":{"file_path":"%s","content":"x"}}' "$1" "$2"; }
r() { printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$1"; }
b() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
BASH='{"tool_name":"Bash","tool_input":{"command":"echo hi"}}'

echo "== scratch repository with this checkout's control plane, a change record on branch change/demo at the implement phase"
cd "$A" || exit 1
git init -q -b main . && git config user.name Eval && git config user.email eval@example.invalid
mkdir -p lib test docs; echo 'puts 1' > lib/app.rb; echo 'puts 2' > lib/other.rb; echo '# App' > docs/index.md
git add -A; git commit -qm init
sf init --no-onboard --maturity off >/dev/null 2>&1 || { echo "init failed"; sf init --no-onboard --maturity off; }
echo "-- hooks install (prints the mode in effect and where it comes from)"
sf hooks install --claude; sf hooks install --codex
git add -A; git commit -qm 'control plane'
git checkout -qb change/demo; sf change new demo >/dev/null
sed -i 's/^status: intake.*/status: in_progress/; s/^current_phase: intake.*/current_phase: implement/' changes/demo/metadata.yml
git add -A; git commit -qm record
echo "active skill: implementation (writes lib, test, 05-implementation; deny_write .ai, docs, evidence phases; deny_read .ai/harness-evals and the evaluation/attack evidence)"
echo "mode: $(sf doctor 2>&1 | grep 'guard hook')"

echo "== claim: Edit, Write, MultiEdit, NotebookEdit are checked against the write and deny_write sets"
g 0 "Write lib/app.rb (write set)" "$(w Write lib/app.rb)"
g 0 "Edit test/app_test.rb (write set)" '{"tool_name":"Edit","tool_input":{"file_path":"test/app_test.rb","old_string":"a","new_string":"b"}}'
g 2 "Write .ai/rules/ruby.md (deny_write, the README's example)" "$(w Write .ai/rules/ruby.md)"
g 2 "MultiEdit docs/index.md (deny_write)" '{"tool_name":"MultiEdit","tool_input":{"file_path":"docs/index.md","edits":[]}}'
g 2 "NotebookEdit changes/demo/06-verification/x.ipynb (deny_write)" '{"tool_name":"NotebookEdit","tool_input":{"notebook_path":"changes/demo/06-verification/x.ipynb"}}'
g 2 "Write changes/demo/07-evaluation/results.md (another phase's evidence)" "$(w Write changes/demo/07-evaluation/results.md)"
g 2 "Write README.md (not in the write set)" "$(w Write README.md)"

echo "== claim: Read is checked against deny_read only (read lists are advisory context)"
g 0 "Read lib/app.rb" "$(r lib/app.rb)"
g 0 "Read docs/index.md (not in implementation's read list, not denied)" "$(r docs/index.md)"
g 2 "Read .ai/harness-evals/README.md (deny_read)" "$(r .ai/harness-evals/README.md)"
g 2 "Read changes/demo/07-evaluation/evidence/x.txt (deny_read)" "$(r changes/demo/07-evaluation/evidence/x.txt)"

echo "== claim: Grep and Glob are checked against deny_read by their path and a glob pattern's static prefix"
g 0 "Grep path lib" '{"tool_name":"Grep","tool_input":{"pattern":"puts","path":"lib"}}'
g 2 "Grep path .ai/harness-evals" '{"tool_name":"Grep","tool_input":{"pattern":"x","path":".ai/harness-evals"}}'
g 0 "Glob pattern lib/**/*.rb" '{"tool_name":"Glob","tool_input":{"pattern":"lib/**/*.rb"}}'
g 2 "Glob pattern .ai/harness-evals/**/*.yml (static prefix)" '{"tool_name":"Glob","tool_input":{"pattern":".ai/harness-evals/**/*.yml"}}'
g 2 "Glob pattern **/*.yml with path .ai/harness-evals" '{"tool_name":"Glob","tool_input":{"pattern":"**/*.yml","path":".ai/harness-evals"}}'

echo "== claim: paths are judged after symlinks resolve"
ln -s .ai/harness-evals "$A/link"
g 2 "Read link/README.md where link -> .ai/harness-evals" "$(r link/README.md)"
g 2 "Grep path link" '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"link"}}'
rm "$A/link"

echo "== claim: Bash is read segment by segment, following cd and pushd, expanding globs and braces"
g 2 "Bash cat .ai/harness-evals/README.md (deny_read path)" "$(b 'cat .ai/harness-evals/README.md')"
g 2 "Bash cd .ai && cat harness-evals/README.md (cd followed)" "$(b 'cd .ai && cat harness-evals/README.md')"
g 2 "Bash pushd .ai/harness-evals && ls (pushd followed)" "$(b 'pushd .ai/harness-evals && ls')"
g 2 "Bash cd lib && cd .. && cd .ai/policies && sed -i s/block/warn/ enforcement.yml (own configuration through cd)" "$(b 'cd lib && cd .. && cd .ai/policies && sed -i s/block/warn/ enforcement.yml')"
g 2 "Bash cat .ai/harness-evals/*.md (glob expanded)" "$(b 'cat .ai/harness-evals/*.md')"
g 2 "Bash cat .ai/{README.md,harness-evals/README.md} (brace expanded)" "$(b 'cat .ai/{README.md,harness-evals/README.md}')"
g 0 "Bash cat lib/{app,other}.rb (brace expanded to readable paths)" "$(b 'cat lib/{app,other}.rb')"

echo "== claim: Bash is refused when it names a deny_read path, a deny_write path the skill may not read, protected policy or harness material, or the guard's own configuration; it may name what the skill may read"
g 0 "Bash cat lib/app.rb && bundle exec rake test (readable paths)" "$(b 'cat lib/app.rb && bundle exec rake test')"
g 0 "Bash cat .ai/workflow.yml (control plane is readable)" "$(b 'cat .ai/workflow.yml')"
g 2 "Bash cat .ai/policies/budget.yml (protected policy)" "$(b 'cat .ai/policies/budget.yml')"
g 2 "Bash ls .ai/harness-evals (harness material)" "$(b 'ls .ai/harness-evals')"
g 2 "Bash cat changes/demo/07-evaluation/results.md (deny_write the skill may not read)" "$(b 'cat changes/demo/07-evaluation/results.md')"
g 2 "Bash cat .ai/policies/enforcement.yml (own configuration)" "$(b 'cat .ai/policies/enforcement.yml')"
g 2 "Bash cat .claude/settings.json (own configuration)" "$(b 'cat .claude/settings.json')"
g 2 "Bash cat .claude/settings.local.json (own configuration)" "$(b 'cat .claude/settings.local.json')"
g 2 "Bash cat .codex/hooks.json (own configuration)" "$(b 'cat .codex/hooks.json')"
g 2 "Bash ls .soft-foundry (own configuration: everything under .soft-foundry/)" "$(b 'ls .soft-foundry')"
g 2 "Bash tail .soft-foundry/guard.log (own configuration)" "$(b 'tail .soft-foundry/guard.log')"
g 2 "Bash cat $A/.ai/policies/enforcement.yml (absolute path into the root)" "$(b "cat $A/.ai/policies/enforcement.yml")"
g 2 "Bash cd /tmp && cat $A/.ai/policies/budget.yml (absolute path after leaving the root)" "$(b "cd /tmp && cat $A/.ai/policies/budget.yml")"

echo "== claim: a call the guard cannot decide (an unknown ~user, a NUL byte) is refused"
g 2 "Bash cat ~nosuchuser_zz/x (unknown ~user)" "$(b 'cat ~nosuchuser_zz/x')"
g 2 "Bash with a NUL byte in the command" '{"tool_name":"Bash","tool_input":{"command":"cat lib/app\u0000.rb"}}'
g 2 "malformed stdin (not JSON)" 'not json'
g 2 "payload without tool_name" '{"tool_input":{}}'

echo "== claim: the guard's own configuration cannot be written from inside a guarded session (write tools)"
g 2 "Write .ai/policies/enforcement.yml" "$(w Write .ai/policies/enforcement.yml)"
g 2 "Edit .soft-foundry/enforcement.yml" '{"tool_name":"Edit","tool_input":{"file_path":".soft-foundry/enforcement.yml","old_string":"block","new_string":"off"}}'
g 2 "Write .claude/settings.json" "$(w Write .claude/settings.json)"
g 2 "Write .claude/settings.local.json" "$(w Write .claude/settings.local.json)"
g 2 "Write .codex/hooks.json" "$(w Write .codex/hooks.json)"
g 2 "Write .soft-foundry/guard-baseline.yml" "$(w Write .soft-foundry/guard-baseline.yml)"

echo "== claim: the guard records its configuration before each shell command and, as the PostToolUse hook, restores whatever the command changed and refuses"
POLICY=$A/.ai/policies/enforcement.yml; SETTINGS=$A/.claude/settings.json; OVERRIDE=$A/.soft-foundry/enforcement.yml; BASE=$A/.soft-foundry/guard-baseline.yml
before_policy=$(cat "$POLICY"); before_settings=$(cat "$SETTINGS")
a "no baseline before the first shell call (hooks install cleared it)" test ! -e "$BASE"
g 0 "pre-call: Bash echo hi (records the baseline, allows the call)" "$BASH"
a "baseline recorded at .soft-foundry/guard-baseline.yml" test -f "$BASE"
echo "-- the call, spelled however it likes, downgrades the guard: mode off in the policy, an override file, a hook entry removed"
sed -i 's/mode: block/mode: off/' "$POLICY"; mkdir -p "$(dirname "$OVERRIDE")"; printf 'guard:\n  mode: off\n' > "$OVERRIDE"; printf '{"hooks":{}}\n' > "$SETTINGS"
echo "   mode during the call: $(sf doctor 2>&1 | grep 'guard hook' | sed 's/.*mode:/mode:/')"
ga 2 "post-call: guard --after restores and refuses (reads the mode after restoring)"
a "policy restored byte for byte" test "$(cat "$POLICY")" = "$before_policy"
a "hook settings restored byte for byte" test "$(cat "$SETTINGS")" = "$before_settings"
a "the override that did not exist before the call is removed" test ! -e "$OVERRIDE"
a "the baseline is consumed by the check" test ! -e "$BASE"
a "mode back to block" test "$(sf doctor 2>&1 | grep -c 'mode: block, repository policy')" = 1
ga 0 "post-call with nothing changed and no baseline is quiet"
echo "-- a baseline missing after a call (removed during it): the committed policy is the fallback"
g 0 "pre-call: Bash echo hi" "$BASH"
sed -i 's/mode: block/mode: warn/' "$POLICY"; rm -f "$BASE"
ga 2 "post-call with the baseline gone: restored from git HEAD, the note says so"
a "policy restored from the commit" test "$(cat "$POLICY")" = "$before_policy"
echo "-- a change made between calls, in the maintainer's own shell, stands"
printf 'guard:\n  mode: warn\n' > "$OVERRIDE"
g 0 "pre-call: Bash echo hi (the override is now the baseline)" "$BASH"
ga 0 "post-call: nothing changed during the call, quiet"
a "the maintainer's override stands" test -f "$OVERRIDE"
echo "-- a stale baseline left by an interrupted call is refreshed at the next shell call (BASELINE_MAX_AGE 1800 s)"
g 0 "pre-call: Bash echo hi" "$BASH"; touch -d '40 minutes ago' "$BASE"; old=$(stat -c %Y "$BASE")
g 0 "pre-call again with a 40-minute-old baseline" "$BASH"; new=$(stat -c %Y "$BASE")
a "the stale baseline was rewritten" test "$new" != "$old"
ga 0 "post-call: quiet"
echo "-- only a shell call records a baseline"
g 2 "Write .ai/rules/ruby.md (a write tool call)" "$(w Write .ai/rules/ruby.md)"
a "no baseline after a write-tool call" test ! -e "$BASE"

echo "== claim: warn reports and lets the call through; block refuses; off says nothing; the override and the variable, the variable winning"
echo "-- machine-local override .soft-foundry/enforcement.yml says warn (written by the maintainer between calls)"
echo "   doctor: $(sf doctor 2>&1 | grep 'guard hook' | sed 's/.*mode:/mode:/')"
g 0 "Write .ai/rules/ruby.md under the override: reported with '! warn', exit 0" "$(w Write .ai/rules/ruby.md)"
g 2 "same call with SOFT_FOUNDRY_GUARD=block: the variable wins over the override" "$(w Write .ai/rules/ruby.md)" SOFT_FOUNDRY_GUARD=block
g 0 "same call with SOFT_FOUNDRY_GUARD=off: silent, exit 0" "$(w Write .ai/rules/ruby.md)" SOFT_FOUNDRY_GUARD=off
g 0 "SOFT_FOUNDRY_GUARD=nonsense is ignored: the override (warn) applies" "$(w Write .ai/rules/ruby.md)" SOFT_FOUNDRY_GUARD=nonsense
echo "   doctor with SOFT_FOUNDRY_GUARD=off: $(clean env SOFT_FOUNDRY_GUARD=off $SF doctor 2>&1 | grep 'guard hook' | sed 's/.*mode:/mode:/')"
rm -f "$OVERRIDE"
echo "   doctor after the override is removed: $(sf doctor 2>&1 | grep 'guard hook' | sed 's/.*mode:/mode:/')"
g 2 "Write .ai/rules/ruby.md under repository policy again: refused" "$(w Write .ai/rules/ruby.md)"

echo "== claim: outside a change branch, or once a change is closed, nothing is guarded"
git checkout -q main
g 0 "Write .ai/rules/ruby.md on main (no change record for the branch)" "$(w Write .ai/rules/ruby.md)"
git checkout -q change/demo
sed -i 's/^status: in_progress.*/status: closed/' changes/demo/metadata.yml
g 0 "Write .ai/rules/ruby.md with the change closed" "$(w Write .ai/rules/ruby.md)"
git checkout -q -- changes/demo/metadata.yml
g 2 "Write .ai/rules/ruby.md with the change in progress again" "$(w Write .ai/rules/ruby.md)"

echo "== claim (README): Codex sends Bash with command as an array and file edits as apply_patch; Grok sends write, search_replace, read_file, run_terminal_command"
g 2 "Bash command as an array naming harness material" '{"tool_name":"Bash","tool_input":{"command":["cat",".ai/harness-evals/README.md"]}}'
g 2 "apply_patch updating .ai/rules/ruby.md" '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: .ai/rules/ruby.md\n@@\n-a\n+b\n*** End Patch"}}'
g 0 "apply_patch adding lib/new.rb" '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Add File: lib/new.rb\n+puts 3\n*** End Patch"}}'
g 2 "write (Grok) to .ai/rules/ruby.md" "$(w write .ai/rules/ruby.md)"
g 2 "search_replace (Grok) on docs/index.md" "$(w search_replace docs/index.md)"
g 2 "read_file (Grok) target_file .ai/harness-evals/README.md" '{"tool_name":"read_file","tool_input":{"target_file":".ai/harness-evals/README.md"}}'
g 2 "run_terminal_command (Grok) cat .ai/harness-evals/README.md" '{"tool_name":"run_terminal_command","tool_input":{"command":"cat .ai/harness-evals/README.md"}}'
g 0 "WebFetch (not a guarded tool)" '{"tool_name":"WebFetch","tool_input":{"url":"https://example.invalid"}}'

echo "== the machine-local guard log (scratch repository): every non-allow decision and every tamper"
sed 's/^/      /' "$A/.soft-foundry/guard.log" | tail -12
echo "SUMMARY pass=$pass unexpected=$bad"
[ "$bad" = 0 ]
