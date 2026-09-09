#!/bin/bash
# EVAL-012: Soft Foundry-side failure: packaged .ai/workflow.yml missing. Persona a hitting a broken package.
source "$(dirname "$0")/lib.sh"
start_log EVAL-012-internal-failure.log "EVAL-012 broken package (missing .ai/workflow.yml): exit 4, upstream guidance, nothing written, no secrets"
BROKEN=$SCRATCH/soft-foundry-broken
rm -rf "$BROKEN"; mkdir -p "$BROKEN"
runsh "rsync -a --exclude .git --exclude .soft-foundry --exclude 'changes/*/' $REPO/ $BROKEN/ && rm $BROKEN/.ai/workflow.yml && test ! -e $BROKEN/.ai/workflow.yml && echo 'broken copy ready without .ai/workflow.yml'"
SFB="$RUBY -I$BROKEN/lib $BROKEN/exe/soft-foundry"
T=$(new_repo eval-012); cd "$T"
printf 'x\n' > app.rb
run git add -A; run git commit -q -m "Project files"
note "STEP 1: init from the broken copy with canary secrets in the environment (stdout and stderr captured separately)"
CANARY=sk-canary-EVAL012-SECRET-VALUE
runsh "cd $T && env OPENAI_API_KEY=$CANARY ANTHROPIC_API_KEY=$CANARY XAI_API_KEY=$CANARY $RUBY -I$BROKEN/lib $BROKEN/exe/soft-foundry init > $SCRATCH/eval-012.stdout 2> $SCRATCH/eval-012.stderr; echo exit=\$?"
RC1=$(sed -n '/STEP 1/,$p' "$LOG" | grep -m1 '^exit=' | cut -d= -f2)
note "STEP 1 stdout"
runsh "cat $SCRATCH/eval-012.stdout; echo '[end of stdout]'"
note "STEP 1 stderr"
runsh "cat $SCRATCH/eval-012.stderr; echo '[end of stderr]'"
note "STEP 1 post-state"
run git status --porcelain --untracked-files=all
runsh "ls -A"
note "STEP 2: the same run with --dry-run also fails the same way"
runsh "cd $T && env OPENAI_API_KEY=$CANARY $RUBY -I$BROKEN/lib $BROKEN/exe/soft-foundry init --dry-run --no-onboard; echo exit=\$?"
note "STEP 3: secret and path scan of both streams"
runsh "grep -c 'EVAL012-SECRET' $SCRATCH/eval-012.stdout $SCRATCH/eval-012.stderr; grep -c '$T' $SCRATCH/eval-012.stdout $SCRATCH/eval-012.stderr; grep -c '$BROKEN' $SCRATCH/eval-012.stderr; grep -c \"$HOME\" $SCRATCH/eval-012.stderr; true"
note "ASSERTIONS"
assert "AC-013 exit 4" "[ $RC1 -eq 4 ]"
assert "AC-013 message states the fault is in Soft Foundry" "grep -q 'This is a defect in Soft Foundry .*, not in your repository' $SCRATCH/eval-012.stderr"
assert "AC-013 message names the missing file and component" "grep -q 'internal failure in package: packaged file missing: .ai/workflow.yml' $SCRATCH/eval-012.stderr"
assert "AC-013 points to the upstream repository with fork/pull-request guidance" "grep -q 'fork https://github.com/jmscholen/soft_foundry' $SCRATCH/eval-012.stderr && grep -q 'pull request or issue' $SCRATCH/eval-012.stderr"
assert "AC-013 nothing written to the target" "[ -z \"$(git -C $T status --porcelain --untracked-files=all)\" ] && [ ! -e $T/.ai ] && [ ! -e $T/.soft-foundry ]"
assert "MIT-012 no secret value in stdout or stderr" "! grep -q 'EVAL012-SECRET' $SCRATCH/eval-012.stdout $SCRATCH/eval-012.stderr"
assert "MIT-012 no absolute target path in the diagnostic" "! grep -q '$T' $SCRATCH/eval-012.stderr"
assert "MIT-012 no absolute gem/source path in the diagnostic" "! grep -q '$BROKEN' $SCRATCH/eval-012.stderr"
assert "MIT-012 no home directory path in the diagnostic" "! grep -q \"$HOME\" $SCRATCH/eval-012.stderr"
assert "AC-013 guidance goes to stderr, stdout is empty" "[ ! -s $SCRATCH/eval-012.stdout ]"
finish EVAL-012
