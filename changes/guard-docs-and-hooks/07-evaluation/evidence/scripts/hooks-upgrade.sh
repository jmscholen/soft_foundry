#!/bin/bash
# EVAL-003 (REQ-GDH-001): a maintainer rerunning `soft-foundry hooks install
# --claude` on a repository whose settings still carry the old matcher and no
# PostToolUse entry, which is the state this repository was in before commit
# b9f4d7c. Runs in a scratch repository under the system temp directory with
# this checkout's library; nothing in this repository is written. Run as:
#   bash changes/guard-docs-and-hooks/07-evaluation/evidence/scripts/hooks-upgrade.sh "$(mktemp -d)"
set -u
REPO=$(cd "$(dirname "$0")/../../../../.." && pwd)
S=$1; A=$S/app; H=$S/home; mkdir -p "$A/.claude" "$H"
SF="ruby -I$REPO/lib $REPO/exe/soft-foundry"
clean() { env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$H" TMPDIR="$S" LANG=C.UTF-8 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 "$@"; }
sf() { clean $SF "$@"; }
pass=0; bad=0
a() { label=$1; shift; if "$@"; then echo "ok         | $label"; pass=$((pass+1)); else echo "UNEXPECTED | $label"; bad=$((bad+1)); fi; }
j() { ruby -rjson -e 'd=JSON.parse(File.read(ARGV[0])); puts eval(ARGV[1])' "$1" "$2"; }
COMMITTED=$REPO/.claude/settings.json
SETTINGS=$A/.claude/settings.json

cd "$A" || exit 1
git init -q -b main . && git config user.name Eval && git config user.email eval@example.invalid
mkdir -p lib; echo 'puts 1' > lib/app.rb; git add -A; git commit -qm init
sf init --no-onboard --maturity off >/dev/null 2>&1
echo "== the settings file as this repository had it before b9f4d7c: the old matcher, no PostToolUse, plus an unrelated hook and an unrelated key that must survive"
cat > "$SETTINGS" <<'JSON'
{
  "permissions": { "allow": ["Bash(ls:*)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "WebFetch", "hooks": [ { "type": "command", "command": "echo unrelated hook" } ] },
      {
        "matcher": "Edit|Write|MultiEdit|NotebookEdit|Read|Bash",
        "hooks": [ { "type": "command", "command": "# soft-foundry:guard\nif [ -x exe/soft-foundry ] && [ -f lib/soft_foundry.rb ]; then ruby -Ilib exe/soft-foundry guard; elif command -v soft-foundry >/dev/null 2>&1; then soft-foundry guard; fi" } ]
      }
    ]
  }
}
JSON
git add -A; git commit -qm 'old hook settings'
echo "-- doctor before the rerun"; sf doctor 2>&1 | grep 'guard hook'
echo "   PreToolUse matcher before: $(j "$SETTINGS" 'd["hooks"]["PreToolUse"].map { |e| e["matcher"] }.inspect')"
echo "   PostToolUse before: $(j "$SETTINGS" 'd["hooks"].fetch("PostToolUse", []).size')"
mkdir -p "$A/.soft-foundry"; printf 'version: 1\nfiles: {}\n' > "$A/.soft-foundry/guard-baseline.yml"

echo "== soft-foundry hooks install --claude on the existing repository (its output):"
sf hooks install --claude 2>&1 | sed 's/^/   /'
a "exactly one guard entry in PreToolUse" test "$(j "$SETTINGS" 'd["hooks"]["PreToolUse"].count { |e| e["hooks"].any? { |h| h["command"].include?("soft-foundry:guard\n") } }')" = 1
a "the PreToolUse matcher now reads Edit|Write|MultiEdit|NotebookEdit|Read|Grep|Glob|Bash" test "$(j "$SETTINGS" 'd["hooks"]["PreToolUse"].find { |e| e["hooks"].any? { |h| h["command"].include?("soft-foundry:guard\n") } }["matcher"]')" = "Edit|Write|MultiEdit|NotebookEdit|Read|Grep|Glob|Bash"
a "a PostToolUse entry with matcher Bash runs guard --after" test "$(j "$SETTINGS" 'e=d["hooks"]["PostToolUse"].find { |e| e["hooks"].any? { |h| h["command"].include?("soft-foundry:guard-after") } }; e && e["matcher"] == "Bash" && e["hooks"][0]["command"].include?("guard --after")')" = true
a "the unrelated WebFetch hook is kept" test "$(j "$SETTINGS" 'd["hooks"]["PreToolUse"].any? { |e| e["matcher"] == "WebFetch" }')" = true
a "the unrelated permissions key is kept" test "$(j "$SETTINGS" 'd["permissions"]["allow"].inspect')" = '["Bash(ls:*)"]'
a "the guard entries equal this repository's committed .claude/settings.json entries" test "$(j "$SETTINGS" 'd["hooks"].transform_values { |es| es.select { |e| e["hooks"].any? { |h| h["command"].include?("soft-foundry:guard") } } }.to_json')" = "$(j "$COMMITTED" 'd["hooks"].to_json')"
a "a baseline left by an interrupted call is cleared by the maintainer's own install" test ! -e "$A/.soft-foundry/guard-baseline.yml"
echo "-- doctor after the rerun"; sf doctor 2>&1 | grep 'guard hook'

echo "== running it a second time changes nothing"
cp "$SETTINGS" "$S/once.json"; sf hooks install --claude >/dev/null 2>&1
a "second install leaves the file identical" cmp -s "$SETTINGS" "$S/once.json"

echo "== --codex writes the same hook into .codex/hooks.json; it equals this repository's committed file"
sf hooks install --codex 2>&1 | sed 's/^/   /'
a ".codex/hooks.json equals the committed one (JSON compared)" test "$(j "$A/.codex/hooks.json" 'd.to_json')" = "$(j "$REPO/.codex/hooks.json" 'd.to_json')"

echo "== --claude --local writes .claude/settings.local.json; doctor still reports installed"
sf hooks install --claude --local 2>&1 | sed 's/^/   /'
a "settings.local.json carries the guard" test "$(j "$A/.claude/settings.local.json" 'd["hooks"]["PreToolUse"].size')" = 1
sf hooks uninstall --claude --local 2>&1 | sed 's/^/   /'

echo "== hooks uninstall --claude removes only Soft Foundry's entries"
sf hooks uninstall --claude 2>&1 | sed 's/^/   /'
a "no guard entry left" test "$(j "$SETTINGS" 'd["hooks"]["PreToolUse"].any? { |e| e["hooks"].any? { |h| h["command"].include?("soft-foundry:guard") } }')" = false
a "PostToolUse removed when empty" test "$(j "$SETTINGS" 'd["hooks"].key?("PostToolUse")')" = false
a "the unrelated WebFetch hook is still there" test "$(j "$SETTINGS" 'd["hooks"]["PreToolUse"].any? { |e| e["matcher"] == "WebFetch" }')" = true
echo "-- doctor with the Claude hook removed (codex still installed)"; sf doctor 2>&1 | grep 'guard hook'
sf hooks uninstall --codex >/dev/null 2>&1
echo "-- doctor with no hook installed (the line says what to run)"; sf doctor 2>&1 | grep 'guard hook'
echo "SUMMARY pass=$pass unexpected=$bad"
[ "$bad" = 0 ]
