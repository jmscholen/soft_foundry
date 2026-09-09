#!/bin/bash
# EVAL-004: upgrade with a committed maintainer edit: conflict, then --force. Personas a and b.
# A "canonical change" is simulated with a copy of the Soft Foundry source (next-version) whose
# .ai/rules/general.md and .ai/rules/ruby.md differ from the version that was installed.
source "$(dirname "$0")/lib.sh"
start_log EVAL-004-conflict-then-force.log "EVAL-004 committed user edit conflicts on upgrade, --force resolves it; untouched owned files are updated"
T=$(new_repo eval-004); cd "$T"
printf 'puts 1\n' > app.rb
run git add -A; run git commit -q -m "Project files"
note "STEP 1: install current version and commit"
run $SF init --no-onboard; RC1=$?
run git add -A; run git commit -q -m "Adopt Soft Foundry"
note "STEP 2: maintainer edits .ai/rules/general.md and commits"
runsh "printf '\n## Acme addendum\nAlways run the smoke suite.\n' >> .ai/rules/general.md"
run git add -A; run git commit -q -m "Local rule addendum"
run shasum -a 256 .ai/rules/general.md
USER_HASH=$(shasum -a 256 .ai/rules/general.md | cut -d' ' -f1)
note "STEP 3: build a next-version copy of Soft Foundry whose canonical general.md and ruby.md changed"
NEXT=$SCRATCH/soft-foundry-next
rm -rf "$NEXT"; mkdir -p "$NEXT"
runsh "rsync -a --exclude .git --exclude .soft-foundry --exclude 'changes/*/' $REPO/ $NEXT/ && echo copied"
runsh "printf '\n<!-- canonical revision for upgrade evaluation -->\n' >> $NEXT/.ai/rules/general.md; printf '\n<!-- canonical revision for upgrade evaluation -->\n' >> $NEXT/.ai/rules/ruby.md; echo appended"
SFNEXT="$RUBY -I$NEXT/lib $NEXT/exe/soft-foundry"
note "STEP 4: upgrade run (next version) without --force"
run $SFNEXT init --no-onboard; RC2=$?
run git status --porcelain
run shasum -a 256 .ai/rules/general.md
runsh "tail -3 .ai/rules/general.md"
runsh "tail -1 .ai/rules/ruby.md"
runsh "grep -A1 'rules/ruby.md' .ai/manifest.yml | head -2; shasum -a 256 .ai/rules/ruby.md"
run git add -A; run git commit -q -m "Upgrade owned files"
note "STEP 5: upgrade run with --force"
run $SFNEXT init --force --no-onboard; RC3=$?
run git status --porcelain
run git diff --stat
run shasum -a 256 .ai/rules/general.md
runsh "grep -A1 'rules/general.md:' .ai/manifest.yml | head -2 || grep 'rules/general.md' .ai/manifest.yml"
runsh "cmp .ai/rules/general.md $NEXT/.ai/rules/general.md && echo 'general.md is canonical (next version)'"
CANON=$?
runsh "$RUBY -ryaml -rdigest -e 'm=YAML.safe_load(File.read(\".ai/manifest.yml\")); h=m[\"files\"][\".ai/rules/general.md\"]; d=Digest::SHA256.file(\".ai/rules/general.md\").hexdigest; puts \"manifest=#{h}\"; puts \"disk=#{d}\"; exit(h==d ? 0 : 1)'"
MH=$?
run git add -A; run git commit -q -m "Accept canonical rule"
note "STEP 6: rerun after force is clean"
run $SFNEXT init --no-onboard; RC4=$?
note "ASSERTIONS"
assert "setup: first install exit 0" "[ $RC1 -eq 0 ]"
assert "AC-006 upgrade run exit 3" "[ $RC2 -eq 3 ]"
assert "AC-006 general.md reported conflict with reason" "sed -n '/STEP 4/,/STEP 5/p' '$LOG' | grep -q '^conflict  .ai/rules/general.md  (differs from manifest hash)'"
assert "AC-006 general.md left untouched (hash unchanged)" "sed -n '/STEP 4/,/STEP 5/p' '$LOG' | grep -q \"^$USER_HASH  .ai/rules/general.md\""
assert "AC-006 other owned file (ruby.md) reported updated and rewritten" "sed -n '/STEP 4/,/STEP 5/p' '$LOG' | grep -q '^updated   .ai/rules/ruby.md  (owned by manifest)' && grep -q 'canonical revision for upgrade evaluation' $T/.ai/rules/ruby.md"
assert "AC-006 git status after upgrade shows only ruby.md and manifest changed" "sed -n '/STEP 4/,/STEP 5/p' '$LOG' | grep -c '^ M ' | grep -qx 2"
assert "REM conflict run prints conflicts: line naming the path" "sed -n '/STEP 4/,/STEP 5/p' '$LOG' | grep -q '^conflicts: .ai/rules/general.md\$'"
assert "REM conflict run prints next: line mentioning git diff and --force" "sed -n '/STEP 4/,/STEP 5/p' '$LOG' | grep '^next: ' | grep -q 'git diff' && sed -n '/STEP 4/,/STEP 5/p' '$LOG' | grep '^next: ' | grep -q -- '--force'"
assert "REM conflicts:/next: lines follow the summary line" "sed -n '/STEP 4/,/STEP 5/p' '$LOG' | grep -n '^summary:\|^conflicts:\|^next:' | cut -d: -f1 | sort -c"
assert "REM force run (no conflicts) prints no conflicts:/next: lines" "! sed -n '/STEP 5/,/STEP 6/p' '$LOG' | grep -Eq '^(conflicts|next): '"
assert "AC-007 --force exit 0" "[ $RC3 -eq 0 ]"
assert "AC-007 general.md reported forced" "sed -n '/STEP 5/,/STEP 6/p' '$LOG' | grep -q '^forced    .ai/rules/general.md  (differs from manifest hash)'"
assert "AC-007 general.md content is canonical" "[ $CANON -eq 0 ]"
assert "AC-007 manifest hash updated to on-disk content" "[ $MH -eq 0 ]"
assert "AC-003 rerun after force: exit 0 and all skipped" "[ $RC4 -eq 0 ] && ! sed -n '/STEP 6/,\$p' '$LOG' | grep -Eq '^(created|updated|conflict|forced) '"
finish EVAL-004
