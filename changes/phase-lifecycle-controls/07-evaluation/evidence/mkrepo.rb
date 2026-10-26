# Builds a scratch gated-track repo with the given phases complete at HEAD.
# usage: ruby -I<foundry>/lib mkrepo.rb DIR SLUG PHASE,PHASE,... [status] [current_phase]
require "soft_foundry"; require "yaml"; require "fileutils"; require "open3"
dir, slug, done, status, cur = ARGV
done = done.to_s.split(",")
foundry = ENV.fetch("FOUNDRY")
FileUtils.rm_rf(dir); FileUtils.mkdir_p(File.join(dir, "lib"))
FileUtils.cp_r(File.join(foundry, ".ai"), dir)
File.write(File.join(dir, "lib/app.rb"), "puts 1\n"); File.write(File.join(dir, "AGENTS.md"), "# agents\n")
sh = ->(*c) { o, e, s = Open3.capture3(*c, chdir: dir); raise "#{c}: #{e}" unless s.success?; o }
sh.("git","init","-q","-b","main"); sh.("git","config","user.email","e@e"); sh.("git","config","user.name","e")
sh.("git","add","."); sh.("git","commit","-q","-m","initial"); sh.("git","checkout","-qb","change/#{slug}")
o,e,s = Open3.capture3("ruby","-I#{foundry}/lib","#{foundry}/exe/soft-foundry","change","new",slug,chdir: dir); raise e unless s.success?
mp = File.join(dir,"changes",slug,"metadata.yml"); t = File.read(mp)
t = t.sub(/^status: .*$/,"status: #{status || 'in_progress'}").sub(/^current_phase: .*$/,"current_phase: #{cur || 'judge'}"); File.write(mp,t)
sh.("git","add","-A"); sh.("git","commit","-q","-m","record"); sha = sh.("git","rev-parse","HEAD").strip
plane = SoftFoundry::ControlPlane.new(dir)
rec = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: plane)
done.each do |id|
  ph = plane.phase(id); d = rec.phase_dir(ph)
  Dir.glob("**/*", base: d).each { |r| p = File.join(d,r); File.write(p, File.read(p).gsub(/\bTBD\b/,"done")) if File.file?(p) }
  h = YAML.safe_load_file(File.join(d,"handoff.yml")).merge("status"=>"complete","commit_sha"=>sha,"completed_at"=>"2026-09-09T00:00:00Z")
  File.write(File.join(d,"handoff.yml"), YAML.dump(h))
end
if ENV["OUTCOME"]
  final = File.join(rec.phase_dir(plane.phase("judge")), "final.md")
  File.write(final, File.read(final).sub(/^## Outcome\n.*$/, "## Outcome\n#{ENV['OUTCOME']}"))
  if ENV["UNDISCHARGED"]
    data = rec.judgment_evidence
    data["undischarged"] = ENV["UNDISCHARGED"].split(",").map { |i| { "id" => i, "description" => "observe #{i} in production" } }
    File.write(rec.judgment_evidence_path, YAML.dump(data))
  end
end
sh.("git","add","-A"); sh.("git","commit","-q","-m","phases")
if ENV["MERGE"]
  sh.("git","checkout","-q","main"); sh.("git","merge","-q","--no-ff","change/#{slug}","-m","merge #{slug}")
end
puts dir
