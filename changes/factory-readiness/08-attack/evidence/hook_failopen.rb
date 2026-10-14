# End to end through the hook entry point (`soft-foundry guard`, JSON on stdin),
# in a scratch repository with an implementation-skill change in block mode.
require "tmpdir"; require "fileutils"; require "json"; require "open3"
src = ARGV[0]
AI = "." + "ai"; SF = "." + "soft-" + "foundry"; EN = "enforce" + "ment.yml"
Dir.mktmpdir("atk-hook-") do |d|
  d = File.realpath(d)
  FileUtils.cp_r(File.join(src, AI), File.join(d, AI)); FileUtils.mkdir_p(File.join(d, "lib")); FileUtils.mkdir_p(File.join(d, "changes/atk"))
  File.write(File.join(d, "changes/atk/metadata.yml"), "---\nchange:\n  id: atk\nrisk: medium\ntrack: gated\nstatus: implementing\ncurrent_phase: implement\nskipped_phases: []\nsurfaces: {}\n")
  sh = ->(*a){ system(*a, chdir: d, out: File::NULL, err: File::NULL) }
  sh.("git","init","-q","-b","change/atk"); sh.("git","add","-A"); sh.("git","-c","user.email=a@b","-c","user.name=a","commit","-qm","x")
  hook = ->(tool, input) {
    out, st = Open3.capture2e({"BUNDLE_GEMFILE"=>nil}, "ruby", "-I", File.join(src, "lib"), File.join(src, "exe/soft-foundry"), "guard", stdin_data: {tool_name: tool, tool_input: input}.to_json, chdir: d)
    "exit #{st.exitstatus} (#{st.exitstatus == 2 ? 'BLOCKS the call' : st.exitstatus.zero? ? 'allows' : 'non-blocking error: the call proceeds'}) #{out.lines.first.to_s.strip[0,90]}"
  }
  puts "control, names the file plainly:        " + hook.("Bash", {"command"=>"echo x > #{AI}/policies/#{EN}"})
  puts "tilde-plus token in the command:        " + hook.("Bash", {"command"=>"cd ~+/#{AI}/policies && echo x > #{EN}"})
  puts "tilde-user token in the command:        " + hook.("Bash", {"command"=>"echo ~nosuchuser/x > #{AI}/policies/#{EN}"})
  puts "NUL byte in a Write path:               " + hook.("Write", {"file_path"=>"lib/a\u0000/../../#{AI}/policies/#{EN}"})
  puts "NUL byte in a Bash command:             " + hook.("Bash", {"command"=>"echo x > #{AI}/policies/#{EN}\u0000"})
  puts "tilde-user then policy name (one cmd):  " + hook.("Bash", {"command"=>"ls ~zzz; echo x > #{AI}/policies/#{EN}"})
  puts "malformed stdin:                        " + (Open3.capture2e("ruby", "-I", File.join(src, "lib"), File.join(src, "exe/soft-foundry"), "guard", stdin_data: "not json", chdir: d).then { |o, s| "exit #{s.exitstatus}" })
end
