#!/bin/bash
# EVAL-010: init with onboarding and no provider credentials. Persona a.
source "$(dirname "$0")/lib.sh"
start_log EVAL-010-no-provider-keys.log "EVAL-010 init with onboarding and no provider keys in the environment"
T=$(new_repo eval-010); cd "$T"
printf 'x\n' > app.rb
run git add -A; run git commit -q -m "Project files"
note "STEP 1: init (onboarding enabled) with OPENAI_API_KEY ANTHROPIC_API_KEY XAI_API_KEY unset"
run env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY -u XAI_API_KEY $SF init; RC1=$?
note "STEP 1 post-state"
run cat .soft-foundry/runtime.yml
run git status --porcelain --untracked-files=all
run git check-ignore -v .soft-foundry/runtime.yml
NC=$(sed -n '/STEP 1: init/,/STEP 1 post/p' "$LOG" | grep -c ' not configured')
NCENV=$(sed -n '/STEP 1: init/,/STEP 1 post/p' "$LOG" | grep -cE '^(openai +not configured \(set OPENAI_API_KEY\)|anthropic +not configured \(set ANTHROPIC_API_KEY\)|xai +not configured \(set XAI_API_KEY\))$')
SFSTATUS=$(git -C "$T" status --porcelain --untracked-files=all | grep -c 'soft-foundry' || true)
note "STEP 2 (legitimate-use): .soft-foundry/ is a plain directory (not a symlink), and re-running onboard against it works as always"
runsh "test -d .soft-foundry && test ! -L .soft-foundry && echo '.soft-foundry is a plain directory'"
PLAINDIR=$?
run env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY -u XAI_API_KEY $SF onboard; RC2=$?
run cat .soft-foundry/runtime.yml
note "ASSERTIONS"
assert "AC-015 exit 0" "[ $RC1 -eq 0 ]"
assert "AC-015 installation succeeded (check: ok, manifest present)" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^check: ok' && [ -f $T/.ai/manifest.yml ]"
assert "AC-015 every provider reported not configured" "[ $NC -eq 3 ]"
assert "REM each not-configured line names the environment variable to set" "[ $NCENV -eq 3 ]"
assert "REM runtime.yml carries no api_key_env value leakage beyond the variable name and no key values" "! grep -q 'sk-' $T/.soft-foundry/runtime.yml"
assert "AC-015 runtime.yml exists" "[ -f $T/.soft-foundry/runtime.yml ]"
assert "AC-015 runtime.yml records configured: false for all three providers" "[ \"$(grep -c 'configured: false' $T/.soft-foundry/runtime.yml)\" = 3 ]"
assert "runtime.yml is gitignored (git status shows nothing under .soft-foundry)" "[ $SFSTATUS -eq 0 ]"
assert "summary line printed after onboarding" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^summary: '"
assert "legitimate-use: .soft-foundry/ is a plain directory, not a symlink" "[ $PLAINDIR -eq 0 ]"
assert "legitimate-use: re-running onboard against the plain .soft-foundry/ directory works as always" "[ $RC2 -eq 0 ] && [ \"$(grep -c 'configured: false' $T/.soft-foundry/runtime.yml)\" = 3 ]"
finish EVAL-010
