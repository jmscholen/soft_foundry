#!/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/bin/ruby
# Builds a scratch repository for the gate-hardening attack phase:
# a copy of the real .ai/ control plane, a record c1 on change/c1 with
# phases through --through complete and committed by hand (the fixture
# pattern the suite uses), nothing sealed by the tool yet.
require "fileutils"
require "open3"
require "yaml"
SRC = "/Users/jscholen-iou/dev/soft_foundry"
$LOAD_PATH.unshift File.join(SRC, "lib")
require "soft_foundry"
require "soft_foundry/harness_eval"

dir = File.expand_path(ARGV.shift)
through = (i = ARGV.index("--through")) ? ARGV[i + 1] : "verify"
LIFECYCLE = %w[intake discover specify threat_model plan implement verify evaluate attack review judge]
def sh(dir, *cmd)
  out, err, st = Open3.capture3(*cmd, chdir: dir)
  raise "#{cmd.join(' ')} failed: #{err}" unless st.success?
  out
end
FileUtils.rm_rf(dir)
FileUtils.mkdir_p(dir)
FileUtils.cp_r(File.join(SRC, ".ai"), dir)
FileUtils.mkdir_p(File.join(dir, "lib"))
File.write(File.join(dir, "lib", "app.rb"), "puts 1\n")
File.write(File.join(dir, "AGENTS.md"), "# agents\n")
sh(dir, "git", "init", "-q", "-b", "main")
sh(dir, "git", "config", "user.email", "attack@example.com")
sh(dir, "git", "config", "user.name", "Attack")
sh(dir, "git", "config", "gc.auto", "0")
sh(dir, "git", "config", "commit.gpgsign", "false")
sh(dir, "git", "add", ".")
sh(dir, "git", "commit", "-q", "-m", "initial")
sh(dir, "git", "checkout", "-qb", "change/c1")
out = StringIO.new; err = StringIO.new
code = SoftFoundry::CLI.new(%w[change new c1], out: out, err: err, root: dir).run
raise "change new failed: #{out.string}#{err.string}" unless code.zero?
plane = SoftFoundry::ControlPlane.new(dir)
record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane)
meta = File.join(record.dir, "metadata.yml")
text = File.read(meta).sub(/^status: .*$/, "status: in_progress")
nxt = LIFECYCLE[LIFECYCLE.index(through) + 1] || "learn"
text = text.sub(/^current_phase: .*$/, "current_phase: #{nxt}")
File.write(meta, text)
sh(dir, "git", "add", "-A"); sh(dir, "git", "commit", "-q", "-m", "record")
head = sh(dir, "git", "rev-parse", "HEAD").strip
LIFECYCLE.take(LIFECYCLE.index(through) + 1).each { |id| SoftFoundry::HarnessEval.complete_phase!(record, id, head) }
sh(dir, "git", "add", "-A"); sh(dir, "git", "commit", "-q", "-m", "phases complete through #{through}")
puts "built #{dir} through #{through}; HEAD #{sh(dir, 'git', 'rev-parse', 'HEAD').strip[0, 12]}"
