require "fileutils"
require "stringio"
require "soft_foundry"
wt, dir, slug, phases, risk = ARGV
FileUtils.rm_rf(dir); FileUtils.mkdir_p(dir)
FileUtils.cp_r(File.join(wt, ".ai"), dir)
FileUtils.mkdir_p(File.join(dir, "lib")); File.write(File.join(dir, "lib/app.rb"), "puts 1\n")
File.write(File.join(dir, "AGENTS.md"), "# agents\n"); File.write(File.join(dir, "README.md"), "# readme\n")
sh = ->(*c) { system(*c, chdir: dir, out: File::NULL) or abort("failed: #{c.join(' ')}") }
sh.("git", "init", "-q", "-b", "main"); sh.("git", "config", "user.email", "e@x"); sh.("git", "config", "user.name", "Eval"); sh.("git", "config", "gc.auto", "0")
sh.("git", "add", "."); sh.("git", "commit", "-qm", "initial"); sh.("git", "checkout", "-qb", "change/#{slug}")
SoftFoundry::CLI.new(["change", "new", slug], out: StringIO.new, err: $stderr, root: dir).run
plane = SoftFoundry::ControlPlane.new(dir)
record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: plane)
m = File.join(record.dir, "metadata.yml")
File.write(m, File.read(m).sub(/^status: .*$/, "status: in_progress").sub(/^current_phase: .*$/, "current_phase: judge").sub(/^risk: .*$/, "risk: #{risk}").sub(/^type: .*$/, "type: feature"))
sh.("git", "add", "-A"); sh.("git", "commit", "-qm", "record")
headsha = `git -C #{dir} rev-parse HEAD`.strip
phases.split(",").each { |id| SoftFoundry::HarnessEval.complete_phase!(record, id, headsha) }
sh.("git", "add", "-A"); sh.("git", "commit", "-qm", "phases complete")
puts dir
