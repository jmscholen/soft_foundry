. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
export PATH=/tmp/evalrun/bin:$PATH
echo "### EVAL-003d signal forwarding (AC-033)"
UPTO=intake,discover,specify,threat_model,plan,implement,verify
for SIG in TERM INT; do
mk /tmp/evalrun/s1 c1 $UPTO in_progress verify; cd /tmp/evalrun/s1; rm -f /tmp/evalrun/stub.log
ruby -I$FOUNDRY/lib $FOUNDRY/exe/soft-foundry phase run evaluate attack --parallel --shell claude --env X=1 >/tmp/evalrun/s1.out 2>&1 &
sleep 1
RP=$!
echo "$SIG: runner pid=$RP stubs running: $(pgrep -f evalrun/bin/claude | wc -l)"
kill -$SIG $RP; sleep 0.7
echo "$SIG: stubs 0.7s after signal: $(pgrep -f evalrun/bin/claude | wc -l)"; sleep 2
wait; echo "$SIG: runner exit=$?"; echo "$SIG: stub log:"; cut -d' ' -f2,3 /tmp/evalrun/stub.log
grep -E '^(phase [a-z]+:|parallel:)' /tmp/evalrun/s1.out
done
