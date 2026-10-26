. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
export PATH=/tmp/evalrun/bin:$PATH
UPTO=intake,discover,specify,threat_model,plan,implement,verify
echo "### EVAL-003b parallel: pass lines, timing, TERM, repeat for lost updates (AC-028,031,033,034)"
mk /tmp/evalrun/q1 c1 $UPTO in_progress verify; cd /tmp/evalrun/q1; rm -f /tmp/evalrun/stub.log
S=$(ruby -e 'print Time.now.to_f'); sf phase run evaluate attack --parallel --shell claude --env X=1 2>&1 | grep -E '^(phase|parallel:)'; echo "exit=${PIPESTATUS[0]}"; E=$(ruby -e 'print Time.now.to_f'); ruby -e "puts 'wall=%.2fs' % ($E-$S)"
grep -E '^(status|commit_sha):' changes/c1/07-evaluation/handoff.yml changes/c1/08-attack/handoff.yml; grep ^current_phase changes/c1/metadata.yml; git log --oneline | head -1
echo "--- single reopen timing (full lifecycle record)"
mk /tmp/evalrun/q2 c1 $ALL; cd /tmp/evalrun/q2; S=$(ruby -e 'print Time.now.to_f'); sf phase reopen intake --reason r >/dev/null; E=$(ruby -e 'print Time.now.to_f'); ruby -e "puts 'reopen intake wall=%.2fs (includes ruby start)' % ($E-$S)"
echo "--- 20 repeats: every YAML parses, both statuses recorded"
bad=0
for i in $(seq 1 20); do
  mk /tmp/evalrun/q3 c1 $UPTO in_progress verify; cd /tmp/evalrun/q3
  sf phase run evaluate attack --parallel --shell claude --env X=1 >/dev/null 2>&1
  ruby -ryaml -e 'ok=Dir["changes/c1/**/*.yml"].all?{|f| YAML.safe_load_file(f, permitted_classes:[Time,Date], aliases: true) rescue false}; h=%w[07-evaluation 08-attack].map{|d| YAML.safe_load_file("changes/c1/#{d}/handoff.yml")["status"]}; exit(ok && h==%w[complete complete] ? 0 : 1)' || { bad=$((bad+1)); echo "run $i BAD"; }
done; echo "bad runs: $bad of 20"
echo "--- TERM (AC-033)"
mk /tmp/evalrun/q4 c1 $UPTO in_progress verify; cd /tmp/evalrun/q4
(sf phase run evaluate attack --parallel --shell claude --env X=1 >/tmp/evalrun/q4.out 2>&1 & echo $! > /tmp/evalrun/q4.pid; wait)&
sleep 1.2; echo "stubs before: $(pgrep -f 'evalrun/bin/claude' | wc -l)"; pkill -TERM -f "exe/soft-foundry phase run evaluate attack"; sleep 3; echo "stubs after: $(pgrep -f 'evalrun/bin/claude' | wc -l)"; grep -E 'interrupt|signal|phase ' /tmp/evalrun/q4.out | head
