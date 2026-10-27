. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
export PATH=/tmp/evalrun/bin:$PATH
echo "### EVAL-003 parallel run (AC-019..023,030..032,034)"
UPTO=intake,discover,specify,threat_model,plan,implement,verify
mk /tmp/evalrun/p1 c1 $UPTO in_progress verify; cd /tmp/evalrun/p1
rm -f /tmp/evalrun/stub.log
echo "--- dry run? no; run with no --env (AC-023)"
S=$(date +%s); sf phase run evaluate attack --parallel --shell claude; echo "exit=$?"; E=$(date +%s); echo "wall=$((E-S))s"
cat /tmp/evalrun/stub.log
grep -E '^(status|commit_sha):' changes/c1/07-evaluation/handoff.yml changes/c1/08-attack/handoff.yml; git rev-parse HEAD; git log --oneline | head -2
grep -E '^current_phase' changes/c1/metadata.yml
echo "--- with --env + secret (AC-022/024)"
mk /tmp/evalrun/p2 c1 $UPTO in_progress verify; cd /tmp/evalrun/p2; rm -f /tmp/evalrun/stub.log
SECRET=zz-secret-Qx9417-zz
sf phase run evaluate attack --parallel --shell claude --env DATABASE_URL="db_{phase}$SECRET" > /tmp/evalrun/p2.out 2>&1; echo "exit=$?"
sed "s/$SECRET/<SECRET>/g" /tmp/evalrun/p2.out; sed "s/$SECRET/<SECRET>/g" /tmp/evalrun/stub.log
echo "secret occurrences in changes/ and output:"; grep -rl "$SECRET" changes /tmp/evalrun/p2.out .soft-foundry 2>/dev/null || echo none
sf ps 2>&1 | grep -c "$SECRET"
echo "--- bad --env (AC-022)"
sf phase run evaluate attack --parallel --env SOFT_FOUNDRY_X=1 --shell claude; echo "exit=$?"
sf phase run evaluate attack --parallel --env lower=1 --shell claude; echo "exit=$?"
sf phase run evaluate attack --parallel --env A=1 --env A=2 --shell claude; echo "exit=$?"
echo "--- refusals (AC-020/021) on pending state"
mk /tmp/evalrun/p3 c1 $UPTO in_progress verify; cd /tmp/evalrun/p3; rm -f /tmp/evalrun/stub.log
sf phase run evaluate review --parallel --shell claude; echo "non-isolated exit=$?"
sf phase run evaluate evaluate --parallel --shell claude; echo "duplicate exit=$?"
sf phase run attack --shell claude; echo "attack alone exit=$?"
sf phase run evaluate --parallel --shell claude --env 'BAD NAME=1' ; echo "exit=$?"
test -f /tmp/evalrun/stub.log && echo "SESSION STARTED" || echo "no session started"; git status --porcelain | grep -v soft-foundry | wc -l
echo "--- one fails (AC-031)"
mk /tmp/evalrun/p4 c1 $UPTO in_progress verify; cd /tmp/evalrun/p4; rm -f /tmp/evalrun/stub.log
STUB_FAIL=attack sf phase run evaluate attack --parallel --shell claude --env X=1; echo "exit=$?"; cat /tmp/evalrun/stub.log
grep -E '^(status|commit_sha):' changes/c1/07-evaluation/handoff.yml changes/c1/08-attack/handoff.yml
echo "--- interrupt (AC-033)"
mk /tmp/evalrun/p5 c1 $UPTO in_progress verify; cd /tmp/evalrun/p5; rm -f /tmp/evalrun/stub.log
sf phase run evaluate attack --parallel --shell claude --env X=1 & PID=$!; sleep 1; pgrep -f "evalrun/bin/claude" | wc -l; kill -INT $PID; wait $PID; echo "exit=$?"; sleep 1; echo "stub processes left: $(pgrep -f 'evalrun/bin/claude' | wc -l)"
