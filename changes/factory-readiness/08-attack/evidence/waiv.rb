$LOAD_PATH.unshift "/home/user/soft_foundry/lib"
require "soft_foundry/gate"; require "soft_foundry/git"; require "yaml"
root = Dir.pwd
plane = SoftFoundry::ControlPlane.new(root)
rec = SoftFoundry::ChangeRecord.new(root, "atk", control_plane: plane)
gate = SoftFoundry::Gate.new(rec, git: SoftFoundry::Git.new(root))
path = File.join(rec.dir, "metadata.yml")
orig = File.read(path)
[["low",[{"phase"=>"judge","rationale"=>"ok"}]],["low",[{"phase"=>"review","rationale"=>"ok"}]],["LOW ",[{"phase"=>"attack","rationale"=>"x"}]],
 ["",[{"phase"=>"attack","rationale"=>"x"}]],["TBD",[{"phase"=>"plan","rationale"=>"x"}]],["medium",[{"phase"=>"verify","rationale"=>"x"}]],
 ["medium",[{"phase"=>"Judge","rationale"=>"x"}]],["medium",[{"phase"=>" judge","rationale"=>"x"}]],["medium",[{"phase"=>"JUDGE","rationale"=>"x"}]],
 ["high",[{"phase"=>"plan","rationale"=>"x"}]],["low",[{"phase"=>"attack","rationale"=>"."}]],["low",[{"phase"=>"attack"}]],["low",["judge"]],
 ["low",[{"phase"=>"learn","rationale"=>"x"}]],["Medium",[{"phase"=>"plan","rationale"=>"x"}]],["low",[{"phase"=>"judge","rationale"=>"x","phase "=>"attack"}]]].each do |risk, skip|
  m = YAML.safe_load(orig, permitted_classes: [Time]); m["risk"]=risk; m["skipped_phases"]=skip
  File.write(path, YAML.dump(m))
  rec2 = SoftFoundry::ChangeRecord.new(root, "atk", control_plane: plane)
  g2 = SoftFoundry::Gate.new(rec2, git: SoftFoundry::Git.new(root))
  c = g2.send(:waivers_check)
  puts "risk=#{risk.inspect} skip=#{skip.inspect[0,60]} -> #{c.outcome} #{c.detail[0,90]}"
end
File.write(path, orig)
