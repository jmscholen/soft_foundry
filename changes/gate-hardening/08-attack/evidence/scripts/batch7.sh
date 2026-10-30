. /tmp/sf-attack2/bin/lib.sh
RB=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
H=changes/c1/07-evaluation/handoff.yml
rewrite() { $RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["commit_sha"]=ARGV[1]; File.write(p, YAML.dump(d))' $H "$1"; }
sealed_then_code() { fresh $1; $B/complete.rb $R evaluate HEAD >/dev/null; git add -A; git commit -qm "evaluate complete on disk"; $B/sf phase seal evaluate | tail -1; echo "// code change" >> lib/app.rb; git commit -qam "change the code after evaluation"; }
{
echo "== 7a: ATK-010 fix bypass: the hand commit of the rewritten commit_sha is given the seal's own subject 'Record c1 evaluate'"
sealed_then_code a030a; rewrite $(git rev-parse HEAD); git add -A; git commit -qm "Record c1 evaluate"
run $B/sf gate evaluate | grep -E 'lineage|current|^07'; run $B/sf phase seal evaluate; log
echo "== 7b: same, forged subject on an empty commit that follows a plain hand commit of the rewrite"
sealed_then_code a030b; rewrite $(git rev-parse HEAD); git add -A; git commit -qm "tweak"; git commit -q --allow-empty -m "Record c1 evaluate"
run $B/sf gate evaluate | grep -E 'lineage|current|^07'
echo "== 7c: same, the forged-subject commit is made the way the tool would: handoff + metadata only, with a reopen first"
sealed_then_code a030c; run $B/sf phase reopen evaluate --reason "code changed after evaluate"; rewrite $(git rev-parse HEAD)
$RB -ryaml -e 'p=ARGV[0]; d=YAML.load_file(p, permitted_classes: [Time, Date]); d["status"]="complete"; File.write(p, YAML.dump(d))' $H; printf '\n' >> changes/c1/07-evaluation/results.md
echo "-- 7c: a one-newline append to results.md is the only 'rerun'"; run $B/sf phase seal evaluate | grep -E 'lineage|sealed|not sealed'; log
echo "== 7d: a phase committed by hand, never sealed: seal says what, and does the next phase's predecessor check pass"
fresh a031; $B/complete.rb $R evaluate HEAD >/dev/null; git add -A; git commit -qm "evaluate complete on disk"
run $B/sf phase seal evaluate; git log --format='%h %s' -n3; $B/complete.rb $R attack HEAD >/dev/null; git add -A; git commit -qm "attack complete by hand"; run $B/sf gate attack | grep -E 'predecessor|lineage'
echo "== 7e: the same with the subject forged on a record that never went through the tool (hand 'Record c1 evaluate' empty commit)"
fresh a032; $B/complete.rb $R evaluate HEAD >/dev/null; git add -A; git commit -qm "Record c1 evaluate"; run $B/sf phase seal evaluate; log
echo "== 7f: ATK-007: hand edit of risk and skipped_phases rides into the seal; does the note name it"
fresh a033; $B/complete.rb $R evaluate HEAD >/dev/null; $RB -ryaml -e 'f=ARGV[0]; d=YAML.load_file(f, permitted_classes: [Time, Date]); d["risk"]="low"; d["skipped_phases"]=[{"phase"=>"review","reason"=>"x"}]; File.write(f, YAML.dump(d))' changes/c1/metadata.yml; git add -A; git commit -qm "evaluate complete on disk"
$RB -ryaml -e 'f=ARGV[0]; d=YAML.load_file(f, permitted_classes: [Time, Date]); d["risk"]="medium"; File.write(f, YAML.dump(d))' changes/c1/metadata.yml
run $B/sf phase seal evaluate; git show --stat --format=%s HEAD | head -8
echo "== 7g: ATK-006: policies/enforcement.yml missing, empty, unparseable, mode block, then check and gate review"
fresh a034; P=.ai/policies/enforcement.yml; cp $P /tmp/sf-attack2/repos/enf.bak; echo "-- original:"; cat $P | head -12
rm $P; git add -A; git commit -qm "drop enforcement policy"; run $B/sf check | grep -iE 'enforcement|warn|error|fail|ok' | head -8
printf 'mode: [unterminated\n' > $P; run $B/sf check | grep -iE 'enforcement|warn|error|fail' | head -8
printf 'mode: BLOCK\n' > $P; run $B/sf check | grep -iE 'enforcement|warn|error|fail' | head -8
cp /tmp/sf-attack2/repos/enf.bak $P
echo "== 7h: EVAL-017 / REQ-036: gate all call count and time at this HEAD (scratch, 11 phases)"
fresh a035; ( time $B/sf gate all >/dev/null ) 2>&1 | grep real
} > $OUT/attack-023-third-pass.txt 2>&1
