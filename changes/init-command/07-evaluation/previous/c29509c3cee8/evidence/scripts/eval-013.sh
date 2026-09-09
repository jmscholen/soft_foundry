#!/bin/bash
# EVAL-013: maintainer previously hand-copied .ai/ without a manifest. Persona d.
source "$(dirname "$0")/lib.sh"
start_log EVAL-013-hand-copied-ai.log "EVAL-013 pre-existing hand-copied .ai/ without manifest: identical skipped, differing conflict, manifest scoped"
T=$(new_repo eval-013); cd "$T"
printf 'x\n' > app.rb
note "STEP 0: hand-copy .ai/ from the Soft Foundry source (without harness-evals, which this evaluation may not read), then edit two files and drop one file"
runsh "rsync -a --exclude 'harness-evals' $REPO/.ai/ $T/.ai/ && echo copied; ls .ai | tr '\n' ' '; echo"
runsh "printf '\n# local tweak\n' >> .ai/rules/security.md; printf '\n# local tweak\n' >> .ai/skills/review/SKILL.md; rm .ai/rules/testing.md; echo edited"
runsh "sed -i '' 's/assessed: false/assessed: true/' .ai/repository.yml; grep -n 'assessed:' .ai/repository.yml"
run git add -A; run git commit -q -m "Hand-copied control plane"
runsh "test ! -e .ai/manifest.yml && echo 'no manifest before init'"
note "STEP 1: init"
run $SF init --no-onboard; RC1=$?
note "STEP 1 post-state"
run git status --porcelain --untracked-files=all
runsh "grep -c . .ai/manifest.yml; grep -c 'rules/security.md' .ai/manifest.yml; grep -c 'skills/review/SKILL.md' .ai/manifest.yml; grep -c 'rules/testing.md' .ai/manifest.yml; grep -c 'repository.yml' .ai/manifest.yml; true"
runsh "$RUBY -ryaml -rdigest -e 'm=YAML.safe_load(File.read(\".ai/manifest.yml\")); f=m[\"files\"]; bad=f.reject{|p,h| File.file?(p) && Digest::SHA256.file(p).hexdigest==h}; puts \"entries=#{f.size} mismatches=#{bad.size} has_security=#{f.key?(\".ai/rules/security.md\")} has_review=#{f.key?(\".ai/skills/review/SKILL.md\")} has_testing=#{f.key?(\".ai/rules/testing.md\")} has_repository=#{f.key?(\".ai/repository.yml\")}\"'"
runsh "tail -2 .ai/rules/security.md; grep -n 'assessed:' .ai/repository.yml"
grep -q 'local tweak' .ai/rules/security.md && grep -q 'local tweak' .ai/skills/review/SKILL.md && TWEAK_INTACT=1 || TWEAK_INTACT=0
run git add -A; run git commit -q -m "Adopt init"
note "STEP 2: init --force"
run $SF init --force --no-onboard; RC2=$?
run git status --porcelain
runsh "cmp .ai/rules/security.md $REPO/.ai/rules/security.md && cmp .ai/skills/review/SKILL.md $REPO/.ai/skills/review/SKILL.md && echo 'both forced files canonical'"
FC=$?
runsh "grep -n 'assessed:' .ai/repository.yml"
FORCED_COUNT=$(sed -n '/STEP 2: init --force/,$p' "$LOG" | grep -c '^forced ')
NEXT_CONFLICT_RUN=$(sed -n '/STEP 1: init/,/STEP 1 post/p' "$LOG" | grep -c '^next: ')
NEXT_FORCE_RUN=$(sed -n '/STEP 2: init --force/,$p' "$LOG" | grep -c '^next: ')
note "ASSERTIONS"
assert "AC-008 exit 3 when conflicts exist" "[ $RC1 -eq 3 ]"
assert "AC-008 identical files skipped with reason identical" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^skipped   .ai/rules/general.md  (identical)'"
assert "AC-008 differing files reported conflict (not in manifest)" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^conflict  .ai/rules/security.md  (not in manifest)' && sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^conflict  .ai/skills/review/SKILL.md  (not in manifest)'"
assert "AC-008 missing file created" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^created   .ai/rules/testing.md' && [ -f $T/.ai/rules/testing.md ]"
assert "AC-008 summary shows conflict 2" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q 'conflict 2, forced 0'"
assert "AC-008 manifest lists only written or verified-identical files (no conflict entries)" "sed -n '/STEP 1 post/,/STEP 2/p' '$LOG' | grep -q 'mismatches=0 has_security=false has_review=false has_testing=true has_repository=false'"
assert "AC-008 conflicting files untouched after the plain run" "[ $TWEAK_INTACT -eq 1 ]"
assert "AC-010 existing repository.yml kept (assessed: true preserved, reported skipped)" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^skipped   .ai/repository.yml  (repository state is owned by this repository)' && grep -q 'assessed: true' $T/.ai/repository.yml"
assert "REM conflicts: line names both conflicted paths" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^conflicts: .ai/rules/security.md, .ai/skills/review/SKILL.md\$'"
assert "REM next: line printed once on the conflict run and not on the force run" "[ $NEXT_CONFLICT_RUN -eq 1 ] && [ $NEXT_FORCE_RUN -eq 0 ]"
assert "check line explains conflicts must be resolved" "sed -n '/STEP 1: init/,/STEP 1 post/p' '$LOG' | grep -q '^check: '"
assert "AC-007 --force exit 0 and both files forced to canonical" "[ $RC2 -eq 0 ] && [ $FC -eq 0 ] && [ $FORCED_COUNT -eq 2 ]"
assert "MIT-006 --force never touches repository.yml" "grep -q 'assessed: true' $T/.ai/repository.yml"
finish EVAL-013
