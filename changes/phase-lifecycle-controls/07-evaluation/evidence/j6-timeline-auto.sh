. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
export PATH=/tmp/evalrun/bin:$PATH
echo "### EVAL-006 auto-reopen of stale phase, timeline (AC-007,008,009,049)"
UPTO=intake,discover,specify,threat_model,plan,implement,verify,evaluate
mk /tmp/evalrun/t1 c1 $UPTO in_progress attack; cd /tmp/evalrun/t1
echo "--- current evidence: run refused, no bytes change (AC-008)"
md5 -q changes/c1/metadata.yml changes/c1/07-evaluation/handoff.yml > /tmp/evalrun/t1.pre
sf phase run evaluate --shell claude 2>&1 | grep -v '^ *!' | head -4; echo "exit=${PIPESTATUS[0]}"
md5 -q changes/c1/metadata.yml changes/c1/07-evaluation/handoff.yml | diff - /tmp/evalrun/t1.pre && echo "bytes unchanged"
echo "--- stale: change app code, run evaluate (AC-007)"
echo 'puts 2' >> lib/app.rb; git commit -qam "code change after evidence"
rm -f /tmp/evalrun/stub.log
sf phase run evaluate --shell claude 2>&1 | grep -E 'reopen|reset|stale|^phase|auto' | head -8
grep -B2 -A14 'phase_reopenings' changes/c1/metadata.yml | grep -E 'phase:|source:|reason:|from_commit|reset:|- ' | head -12
echo "--- stale with predecessor incomplete (AC-009)"
mk /tmp/evalrun/t2 c1 intake,discover,specify,threat_model,plan,implement,evaluate in_progress attack; cd /tmp/evalrun/t2
echo 'puts 2' >> lib/app.rb; git commit -qam code; md5 -q changes/c1/metadata.yml changes/c1/07-evaluation/handoff.yml > /tmp/evalrun/t2.pre
sf phase run evaluate --shell claude 2>&1 | head -3; echo "exit=${PIPESTATUS[0]}"; md5 -q changes/c1/metadata.yml changes/c1/07-evaluation/handoff.yml | diff - /tmp/evalrun/t2.pre && echo "nothing reset"
echo "--- timeline: manual + auto + release + discharge (AC-049)"
OUTCOME=APPROVED mk /tmp/evalrun/t3 c1 $FIN; cd /tmp/evalrun/t3
sf phase reopen learn --reason 'manual rerun of learn' >/dev/null
ruby -ryaml -I$FOUNDRY/lib -rsoft_foundry -e 'pl=SoftFoundry::ControlPlane.new("."); r=SoftFoundry::ChangeRecord.new(".","c1",control_plane: pl); d=r.phase_dir(pl.phase("learn")); f=File.join(d,"handoff.yml"); h=YAML.safe_load_file(f).merge("status"=>"complete","commit_sha"=>`git rev-parse HEAD`.strip,"completed_at"=>"2026-09-09T00:00:00Z"); File.write(f,YAML.dump(h))'
git commit -qam relearn
sf change release --item A=first --item B=second >/dev/null; sf change discharge A --note 'seen live' >/dev/null
ruby -ryaml -e 'f="changes/c1/metadata.yml"; m=YAML.unsafe_load_file(f); m["phase_reopenings"] << {"at"=>"2026-10-01T00:00:00Z","phase"=>"evaluate","reset"=>["evaluate","attack"],"from_commit"=>"abc1234","reason"=>"evidence stale: evidence current failed","source"=>"auto","previous"=>{}}; File.write(f,YAML.dump(m))'
sf change status --json | ruby -rjson -e 'j=JSON.parse(STDIN.read); t=j["timeline"]||j.dig("change","timeline")||[]; t.each{|e| puts [e["at"],e["kind"],e["text"]||e["summary"]].join(" | ")}' 
echo "--- status text"; sf change status c1 | sed -n 1,5p
echo "--- reopened for exploring is distinct: kinds present"; sf change status --json | ruby -rjson -e 'j=JSON.parse(STDIN.read); t=j["timeline"]||[]; puts t.map{|e| e["kind"]}.uniq.inspect'
