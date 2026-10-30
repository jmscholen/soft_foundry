. /tmp/sf-attack2/bin/lib.sh
RB=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
Y() { $RB -ryaml -rjson -e 'f=ARGV.shift; d=YAML.load_file(f, aliases: true, permitted_classes: [Time, Date]); eval(ARGV.shift); File.write(f, YAML.dump(JSON.parse(JSON.generate(d))))' "$@"; }
{
echo "== 5a: criteria_not_covered reasons that survive the two-word test"
$RB $B/build.rb /tmp/sf-attack2/repos/a022 --through judge >/dev/null; cd /tmp/sf-attack2/repos/a022; R=$PWD; E=$(ls changes/c1/14-judgment/evidence.yml)
for spec in '"n/a n/a"' '"no no"' '"xx yy"' '["foo","bar"]' '{"a"=>"foo","b"=>"bar"}' '"ok -"' '"éé éé"' '42' 'true'; do
  echo "-- reason = $spec"; $RB -ryaml -e 'e=YAML.load_file(ARGV[0]); e["criteria_not_covered"]=[{"id"=>"AC-001","reason"=>eval(ARGV[1])}]; File.write(ARGV[0], YAML.dump(e))' $E "$spec"; $B/sf gate judge | grep -E 'criteria covered|^14'
done
echo "-- id not a string: nil, array"; for id in 'nil' '["AC-001"]' '"ac-001"' '"AC-001 "'; do $RB -ryaml -e 'e=YAML.load_file(ARGV[0]); e["criteria_not_covered"]=[{"id"=>eval(ARGV[1]),"reason"=>"deferred to the next release"}]; File.write(ARGV[0], YAML.dump(e))' $E "$id"; echo "id=$id"; $B/sf gate judge | grep -E 'criteria covered'; done
echo "== 5b: whole-id acknowledgement: neighbours and empty/odd ids"
fresh a023; T2=changes/c1/06-verification/tests.yml; H2=changes/c1/06-verification/handoff.yml
setup() { Y $T2 "d[\"checks\"][0][\"id\"]=$1; d[\"checks\"][0][\"result\"]=\"fail\""; Y $H2 "d[\"findings\"]=[{\"id\"=>\"VER-001\",\"severity\"=>\"minor\",\"summary\"=>$2}]; d[\"blocking\"]=[]"; echo "-- id=$1 finding=$2"; $B/sf gate verify | grep -E 'test results'; }
setup '"CHECK-1"' '"CHECK-1.5 failed"'
setup '"CHECK-1"' '"CHECK-1/2 failed"'
setup '"CHECK-1"' '"CHECK-10 failed"'
setup '"CHECK-1"' '"check-1 failed"'
setup '"CHECK-1"' '"preCHECK-1"'
setup '""' '"anything at all."'
setup 'nil' '"anything at all."'
setup '" "' '"anything at all."'
setup '"a.b"' '"axb failed"'
setup '"CHECK-1"' '"CHECK‑1 failed (non-breaking hyphen)"'
echo "== 5c: manifest minimum: one trivial artifact vouches for nothing"
fresh a024; M=changes/c1/07-evaluation/evidence/manifest.yml; $B/complete.rb $R evaluate HEAD >/dev/null
: > changes/c1/07-evaluation/evidence/empty.txt; $RB -ryaml -rdigest -e 'm=YAML.load_file(ARGV[0]); m["artifacts"]=[{"path"=>"evidence/empty.txt","produced_by"=>"x","sha256"=>Digest::SHA256.file(ARGV[1]).hexdigest}]; File.write(ARGV[0], YAML.dump(m))' $M changes/c1/07-evaluation/evidence/empty.txt; run $B/sf gate evaluate | grep -E 'manifest|^07'
echo "-- artifacts with a nil entry / a hash with no path / [{}]"; for a in '[nil]' '[{}]' '[[]]'; do $RB -ryaml -e 'm=YAML.load_file(ARGV[0]); m["artifacts"]=eval(ARGV[1]); File.write(ARGV[0], YAML.dump(m))' $M "$a"; echo "artifacts=$a"; $B/sf gate evaluate | grep -E 'manifest'; done
echo "== 5d: git.branch values that look like options or refs"
for br in '--all' '-q' 'HEAD' 'refs/heads/change/c1' '../c1' 'change/c1 --' 'c1:x' '@{-1}' '@'; do
  fresh a025; $B/complete.rb $R evaluate HEAD >/dev/null; git add -A; git commit -qm "evaluate complete on disk"
  $RB -ryaml -e 'f=ARGV[0]; d=YAML.load_file(f, permitted_classes: [Time, Date]); d["git"]={"branch"=>ARGV[1]}; File.write(f, YAML.dump(d))' changes/c1/metadata.yml "$br"; git commit -qam "branch edited"
  echo "-- git.branch=$br"; $B/sf phase seal evaluate 2>&1 | cut -c1-300; echo "[exit $?] head: $(git log --format=%s -n1)"
done
echo "== 5e: the loop: seal remediation with verify complete, with verify pending, twice"
fresh a026 ; $B/sf phase seal verify | tail -1
$RB $B/complete.rb $R remediate HEAD 2>&1 | tail -1; git add -A; git commit -qm "remediate complete on disk"; run $B/sf phase seal remediate; log
run $B/sf phase seal remediate; log
} > $OUT/attack-022-fix-boundaries.txt 2>&1
