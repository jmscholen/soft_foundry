. /tmp/sf-attack2/bin/lib.sh
RB=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
H=changes/c1/07-evaluation/handoff.yml
rewrite() { $RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["commit_sha"]=ARGV[1]; File.write(p, YAML.dump(d))' $H "$1"; }
seal_then_change() { fresh $1; $B/complete.rb $R evaluate HEAD >/dev/null; git add -A; git commit -qm "evaluate complete on disk"; $B/sf phase seal evaluate | tail -1; echo "// code change" >> lib/app.rb; git commit -qam "change the code after evaluation"; echo "-- gate after code change (expect STALE)"; $B/sf gate evaluate | grep -E 'lineage|current|^07'; }
{
echo "== 4a: ATK-001 variant: the rewritten handoff is committed by hand (message 'tweak') before the gate runs"
seal_then_change a021a; rewrite $(git rev-parse HEAD); git add -A; git commit -qm "tweak notes"
echo "-- gate after hand commit"; run $B/sf gate evaluate; run $B/sf phase seal evaluate; log
echo "== 4b: forged phase_reopenings entry in metadata.yml (reset evaluate, from_commit HEAD) then rewrite"
seal_then_change a021b; HEADSHA=$(git rev-parse HEAD)
$RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["phase_reopenings"]=[{"reset"=>["evaluate"],"from_commit"=>ARGV[1],"source"=>"manual","reason"=>"forged"}]; File.write(p, YAML.dump(d))' changes/c1/metadata.yml $HEADSHA; rewrite $HEADSHA
run $B/sf gate evaluate; run $B/sf phase seal evaluate; log
echo "== 4c: the legitimate path: phase reopen evaluate, rewrite handoff back to complete with the new commit and no rerun"
seal_then_change a021c; run $B/sf phase reopen evaluate --reason "code changed after evaluate"; rewrite $(git rev-parse HEAD)
$RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["status"]="complete"; File.write(p, YAML.dump(d))' $H
run $B/sf gate evaluate | grep -E 'lineage|current|^07|FAIL|PASS'; run $B/sf phase seal evaluate; log
echo "== 4d: the legitimate path through the tool: reopen, complete again at the new HEAD, seal"
seal_then_change a021d; run $B/sf phase reopen evaluate --reason "code changed after evaluate"; $B/complete.rb $R evaluate HEAD >/dev/null; run $B/sf phase seal evaluate; log
echo "== 4e: reopening that names an unrelated phase (reset: [attack]) does not license an evaluate rewrite"
seal_then_change a021e; HEADSHA=$(git rev-parse HEAD)
$RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["phase_reopenings"]=[{"reset"=>["attack"],"from_commit"=>ARGV[1],"source"=>"manual","reason"=>"x"}]; File.write(p, YAML.dump(d))' changes/c1/metadata.yml $HEADSHA; rewrite $HEADSHA
run $B/sf gate evaluate | grep -E 'lineage|^07'
echo "== 4f: reopening with an old from_commit (before the recorded commit) does not license"
seal_then_change a021f
$RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["phase_reopenings"]=[{"reset"=>["evaluate"],"from_commit"=>ARGV[1],"source"=>"manual","reason"=>"x"}]; File.write(p, YAML.dump(d))' changes/c1/metadata.yml $(git rev-list --max-parents=0 HEAD); rewrite $(git rev-parse HEAD)
run $B/sf gate evaluate | grep -E 'lineage|^07'
echo "== 4g: abbreviated and upper-case forms of the recorded sha on disk"
seal_then_change a021g; REC=$($RB -ryaml -e 'puts YAML.load_file(ARGV[0], permitted_classes: [Time, Date])["commit_sha"]' $H); rewrite "${REC:0:12}"; run $B/sf gate evaluate | grep -E 'lineage|^07'; rewrite "$(echo $REC | tr a-f A-F)"; run $B/sf gate evaluate | grep -E 'lineage|^07'
} > $OUT/attack-021-lineage-rebind.txt 2>&1
