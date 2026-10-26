. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
echo "### EVAL-004 release / discharge / close / ci (AC-035..043)"
OUTCOME=APPROVED mk /tmp/evalrun/rl1 c1 $FIN; cd /tmp/evalrun/rl1
sf change release --item 'GOLIVE-1=switch flag on' | head -3; echo "exit=${PIPESTATUS[0]}"
grep -A12 '^release' changes/c1/metadata.yml; grep ^status changes/c1/metadata.yml
echo "--- refusals AC-036"; before=$(git status --porcelain | md5)
OUTCOME=APPROVED mk /tmp/evalrun/rl2 c1 $FIN; cd /tmp/evalrun/rl2; git stash list >/dev/null
for a in "" "--item A=a --item A=b" "--item lower=x" "--item A=" "--item NOEQUALS" "--item A=$(printf 'x%.0s' $(seq 501))"; do sf change release $a 2>&1 | cut -c1-200; echo "exit=${PIPESTATUS[0]}"; done; git status --porcelain | grep -v soft-foundry | wc -l
echo "--- AC-037 judgments"
for o in BLOCKED REJECTED; do OUTCOME=$o mk /tmp/evalrun/rl3 c1 $FIN; (cd /tmp/evalrun/rl3; sf change release --item A=a 2>&1 | cut -c1-220; echo "$o exit=${PIPESTATUS[0]}"); done
mk /tmp/evalrun/rl3 c1 $ALL,learn; (cd /tmp/evalrun/rl3; sf change release --item A=a 2>&1 | cut -c1-220; echo "judge missing exit=${PIPESTATUS[0]}")
echo "--- AC-038 carries U-1,U-2"
OUTCOME=APPROVED UNDISCHARGED=U-1,U-2 mk /tmp/evalrun/rl4 c1 $FIN; cd /tmp/evalrun/rl4; sf change release --item A=a; grep -B1 -A30 '^release' changes/c1/metadata.yml | grep -E 'id:|from:|status|open'
echo "--- AC-039 merged but in_progress/judged: ci"
OUTCOME=APPROVED MERGE=1 mk /tmp/evalrun/rl5 c1 $FIN; cd /tmp/evalrun/rl5; sf ci 2>&1 | grep -v advisory | tail -4; echo "ci exit=${PIPESTATUS[0]}"
echo "--- AC-040 merged released: ci, discharge, close"
sf change release c1 --item A=first --item B=second >/dev/null; sf ci 2>&1 | grep -E 'released|✗ fail|ci failed|✓ ci'; echo "ci exit=${PIPESTATUS[0]}"
sf change close c1; echo "close exit=$?"
sf change discharge A --note 'seen live' --change c1; echo "discharge exit=$?"
sf change discharge A --note again --change c1; echo "dup exit=$?"; sf change discharge ZZ --note n --change c1; echo "unknown exit=$?"
sf change close c1; echo "close with B open exit=$?"
sf change discharge B --note done2 --change c1; sf ci 2>&1 | grep -E 'released|✗ fail|ci failed|✓ ci|close'; echo "ci all-discharged-not-closed exit=${PIPESTATUS[0]}"
sf change close c1; echo "close exit=$?"; grep ^status changes/c1/metadata.yml
sf change discharge A --note n --change c1; echo "discharge on closed exit=$?"
sf phase reopen evaluate --reason r --change c1 2>&1 | cut -c1-120; sf change release c1 --item X=y 2>&1 | cut -c1-140
echo "--- AC-041 malformed release block in check"
OUTCOME=APPROVED mk /tmp/evalrun/rl6 c1 $FIN; cd /tmp/evalrun/rl6; sf change release --item A=a >/dev/null
sf check 2>&1 | tail -1; ruby -ryaml -e 'f="changes/c1/metadata.yml"; m=YAML.unsafe_load_file(f); m["release"]["items"]=[]; File.write(f,YAML.dump(m))'; sf check 2>&1 | tail -3; echo "check exit=${PIPESTATUS[0]}"
ruby -ryaml -e 'f="changes/c1/metadata.yml"; m=YAML.unsafe_load_file(f); m.delete("release"); File.write(f,YAML.dump(m))'; sf check 2>&1 | tail -3
echo "--- AC-043 close non-released"
OUTCOME=APPROVED MERGE=1 mk /tmp/evalrun/rl7 c1 $FIN; cd /tmp/evalrun/rl7; sf change close c1; echo "exit=$?"; grep ^status changes/c1/metadata.yml
