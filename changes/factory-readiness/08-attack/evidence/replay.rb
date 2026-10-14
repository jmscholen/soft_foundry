$LOAD_PATH.unshift "/home/user/soft_foundry/lib"
require "soft_foundry/harness_eval"; require "soft_foundry/cli"; require "yaml"; require "tmpdir"
root = "/home/user/soft_foundry"
plane = SoftFoundry::ControlPlane.new(root)
kase = SoftFoundry::HarnessEval::Case.new(id: "replay", kind: "gate", description: "replay", phase: "", record: {"risk"=>"medium","complete"=>%w[intake discover specify threat_model plan implement verify]}, repository: {}, application: {}, expect: {}, path: "x")
runner = SoftFoundry::HarnessEval::Runner.new(root, plane: plane)
Dir.mktmpdir("atk-replay-") do |d|
  scratch = File.realpath(d)
  record, bound = runner.send(:plant, kase, scratch)
  git = ->(*a){ out = IO.popen(["git","-C",scratch,*a], err: [:child,:out], &:read); out }
  git.("add","-A"); git.("commit","-qm","phases")
  sp = File.join(record.dir, "02-specification", "specification.md")
  puts "baseline:"; 
  gate = ->(ph){ SoftFoundry::Gate.new(SoftFoundry::ChangeRecord.new(scratch, record.slug, control_plane: SoftFoundry::ControlPlane.new(scratch)), git: SoftFoundry::Git.new(scratch)).evaluate(SoftFoundry::ControlPlane.new(scratch).phase(ph)) }
  show = ->(ph){ e = gate.(ph); puts "  #{ph}: " + e.checks.select{|c| [:fail].include?(c.outcome)}.map{|c| "#{c.name}: #{c.detail[0,110]}"}.join(" | ").then{|s| s.empty? ? "no failing checks" : s} }
  show.("specify"); show.("verify")
  File.write(sp, File.read(sp) + "\nAC weakened after evidence.\n")
  git.("add","-A"); git.("commit","-qm","weaken spec")
  head = git.("rev-parse","HEAD").strip
  puts "after spec edit (no restamp):"; show.("specify"); show.("verify")
  hp = record.handoff_path(plane.phase("specify")); h = YAML.safe_load_file(hp, permitted_classes:[Time]); h["commit_sha"]=head
  File.write(hp, YAML.dump(h)); git.("add","-A"); git.("commit","-qm","restamp specify")
  puts "after restamp of specify handoff:"; show.("specify"); show.("verify"); show.("implement")
  # also restamp verify handoff to HEAD without redoing (forge)
  vp = record.handoff_path(plane.phase("verify")); h = YAML.safe_load_file(vp, permitted_classes:[Time]); h["commit_sha"]=git.("rev-parse","HEAD").strip
  File.write(vp, YAML.dump(h)); git.("add","-A"); git.("commit","-qm","restamp verify")
  puts "after also restamping verify handoff to HEAD:"; show.("verify")
  out = StringIO.new
  code = SoftFoundry::CLI.new(["change","close",record.slug], out: out, err: out, root: scratch).run
  puts "close exit #{code}: #{out.string.lines.first(2).join.strip}"
end
