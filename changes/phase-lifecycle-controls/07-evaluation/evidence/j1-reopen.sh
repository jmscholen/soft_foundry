. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
echo "### EVAL-001 reopen evaluate (AC-001,004,005,006)"
mk /tmp/evalrun/j1 c1 $ALL; cd /tmp/evalrun/j1
git status --porcelain | wc -l
cp -r changes /tmp/evalrun/j1-before
sf phase reopen evaluate --reason 'fixture changed'; echo "exit=$?"
git status --porcelain
echo "--- non-handoff/metadata diff vs before:"; diff -rq /tmp/evalrun/j1-before changes | grep -v 'handoff.yml\|metadata.yml' || echo "none"
grep -h '^status:' changes/c1/0[6-9]*/handoff.yml changes/c1/13*/handoff.yml changes/c1/05*/handoff.yml
grep -A16 phase_reopenings changes/c1/metadata.yml; grep -n '^reopenings' changes/c1/metadata.yml
cat changes/c1/08-attack/handoff.yml | head -12
echo "--- gate before redoing"; sf gate evaluate; echo "exit=$?"
echo "--- again (AC-016 nothing to reset?) reopen review x2"
sf phase reopen review --reason r1; echo "exit=$?"; git stash -q; 
sf change status | sed -n 1,20p
echo "--- second reopen of already-pending evaluate"
mk /tmp/evalrun/j1b c1 intake,discover,specify,threat_model,plan,implement,verify; cd /tmp/evalrun/j1b
sf phase reopen evaluate --reason r; echo "exit=$?"; git status --porcelain | wc -l
echo "--- reason refusals (AC-012)"; cd /tmp/evalrun/j1
sf phase reopen evaluate --reason ''; echo "exit=$?"
sf phase reopen evaluate --reason "$(printf 'x%.0s' $(seq 501))"; echo "exit=$?"
sf phase reopen evaluate --reason "$(printf 'bad\001ctl')"; echo "exit=$?"
sf phase reopen evaluate; echo "exit=$?"
sf phase reopen nosuch --reason r; echo "exit=$?"
git status --porcelain | wc -l
echo "--- marker (AC-013)"; SOFT_FOUNDRY_PHASE=evaluate sf phase reopen evaluate --reason r; echo "exit=$?"
SOFT_FOUNDRY_PHASE=evaluate sf change release --item A=b; echo "exit=$?"
SOFT_FOUNDRY_PHASE=evaluate sf change discharge A --note n; echo "exit=$?"
git status --porcelain | wc -l
