. /Users/jscholen-iou/dev/soft_foundry/changes/phase-lifecycle-controls/07-evaluation/evidence/lib.sh
export NO_COLOR=1
echo "### EVAL-011 REV-001 blank discharged_at is open; REV-002 handoffs before metadata (AC-035..043, AC-005)"
OUTCOME=APPROVED mk /tmp/evalrun/q1 c1 $FIN; cd /tmp/evalrun/q1
sf change release c1 --item A=first --item B=second >/dev/null; git add -A; git commit -qm rel
for blank in '""' "'   '"; do
  ruby -ryaml -e 'f="changes/c1/metadata.yml"; m=YAML.unsafe_load_file(f); m["release"]["items"][0]["discharged_at"]=eval(ARGV[0]); File.write(f,YAML.dump(m))' "$blank"
  echo "--- discharged_at=$blank"
  echo "\$ check"; sf check 2>&1 | tail -3; echo "[exit ${PIPESTATUS[0]}]"
  echo "\$ ci"; sf ci 2>&1 | grep -E 'released|open|blank|ci failed|✓ ci|✗'; echo "[exit ${PIPESTATUS[0]}]"
  echo "\$ change close (A blank, B open)"; sf change close c1 2>&1 | cut -c1-240; echo "[exit ${PIPESTATUS[0]}]"
  echo "\$ change status"; sf change status 2>&1 | grep -i 'release\|open\|discharg'
  echo "\$ status --json items"; sf change status --json 2>&1 | ruby -rjson -e 'j=JSON.parse(STDIN.read); puts JSON.pretty_generate(j.select{|k,_| k=~/release|open|timeline/}) rescue puts "n/a"' | grep -i 'discharg\|open_items\|released' | head
  echo "\$ discharge A (blank counts as open, so allowed)"; sf change discharge A --note 'seen live' --change c1 2>&1 | cut -c1-200; echo "[exit ${PIPESTATUS[0]}]"
  git checkout -q changes/c1/metadata.yml
done
echo "--- real discharge still discharges"
sf change discharge A --note 'seen live' --change c1; sf change discharge B --note done2 --change c1; sf change close c1; echo "close exit=$?"; grep ^status changes/c1/metadata.yml
echo "--- REV-002: reopen writes handoffs, then metadata; history matches handoffs"
OUTCOME=APPROVED mk /tmp/evalrun/q2 c1 $ALL; cd /tmp/evalrun/q2
sf phase reopen attack --reason 'redo' ; echo "exit=$?"
grep -h '^status:' changes/c1/0[89]*/handoff.yml changes/c1/1*/handoff.yml
ruby -ryaml -e 'm=YAML.unsafe_load_file("changes/c1/metadata.yml"); r=m["phase_reopenings"]; puts "reopenings=#{r.size} phase=#{r[0]["phase"]} reset=#{r[0]["reset"]&.inspect} reason=#{r[0]["reason"]}"'
echo "--- a crash between renames: metadata.yml rename fails"
OUTCOME=APPROVED mk /tmp/evalrun/q3 c1 $ALL; cd /tmp/evalrun/q3
ruby -I$FOUNDRY/lib -rsoft_foundry -e '
plane=SoftFoundry::ControlPlane.new(Dir.pwd); rec=SoftFoundry::ChangeRecord.new(Dir.pwd,"c1",control_plane: plane)
orig=SoftFoundry::SafeWrite.method(:commit_staged)
SoftFoundry::SafeWrite.define_singleton_method(:commit_staged){|t,p| raise IOError,"killed" if p.end_with?("metadata.yml"); orig.call(t,p)}
begin; rec.transaction{|tx| tx.handoff(plane.phase("attack")){|h| h["status"]="pending"}; tx.metadata{|m| (m["phase_reopenings"]||=[]) << {"phase"=>"attack"}}}; rescue IOError=>e; puts "simulated crash: #{e.message}"; end' 2>&1 | tail -3
echo "attack handoff: $(grep -h '^status:' changes/c1/08-attack/handoff.yml)"; ruby -ryaml -e 'puts "reopenings in metadata: #{Array(YAML.unsafe_load_file("changes/c1/metadata.yml")["phase_reopenings"]).size}"'
echo "\$ change close c1 (a pending phase must refuse)"; sf change close c1 2>&1 | cut -c1-220; echo "[exit ${PIPESTATUS[0]}]"
