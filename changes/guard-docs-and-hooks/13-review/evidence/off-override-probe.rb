# frozen_string_literal: true

# Review probe (guard-docs-and-hooks, 13-review): what the post-call check
# does when the mode in effect is "off" via the machine-local override, as
# README.md and docs/user/guard-hook.md now instruct a maintainer to write.
#
# Runs this checkout's library against a scratch git repository under the
# system temp directory (removed afterwards). Reads nothing under
# .ai/harness-evals; copies the control plane without it.
#
# Usage: bundle exec ruby -Ilib <this file> <repo root>

require "fileutils"
require "json"
require "open3"
require "tmpdir"
require "yaml"

repo = File.expand_path(ARGV.fetch(0))
exe = File.join(repo, "exe", "soft-foundry")
lib = File.join(repo, "lib")

def run(cmd, cwd:, stdin: "", env: {})
  out, err, status = Open3.capture3(env, *cmd, stdin_data: stdin, chdir: cwd)
  [out, err, status.exitstatus]
end

Dir.mktmpdir("sf-review-off-probe-") do |scratch|
  plane_src = File.join(repo, ".ai")
  plane_dst = File.join(scratch, ".ai")
  FileUtils.mkdir_p(plane_dst)
  Dir.children(plane_src).each do |child|
    next if child == "harness-evals"
    FileUtils.cp_r(File.join(plane_src, child), File.join(plane_dst, child))
  end
  FileUtils.mkdir_p(File.join(scratch, "changes"))
  File.write(File.join(scratch, "AGENTS.md"), "# scratch\n")
  run(%w[git init -q -b main], cwd: scratch)
  run(%w[git -c user.email=probe@example.invalid -c user.name=probe add -A], cwd: scratch)
  run(%w[git -c user.email=probe@example.invalid -c user.name=probe commit -q -m scratch], cwd: scratch)

  policy = File.join(scratch, ".ai", "policies", "enforcement.yml")
  override = File.join(scratch, ".soft-foundry", "enforcement.yml")
  baseline = File.join(scratch, ".soft-foundry", "guard-baseline.yml")
  log = File.join(scratch, ".soft-foundry", "guard.log")
  guard = ["ruby", "-I#{lib}", exe, "guard"]
  payload = JSON.generate("tool_name" => "Bash", "tool_input" => { "command" => "ls" })
  mode = lambda do
    out, = run(["ruby", "-I#{lib}", "-e", "require 'soft_foundry'; p SoftFoundry::Guard.mode(Dir.pwd)"], cwd: scratch)
    out.strip
  end

  puts "scratch repository: policy mode #{YAML.safe_load_file(policy).dig('guard', 'mode').inspect}, committed"

  puts "\n== case A: override written as the README says (mode: \"off\", quoted); a Bash call on main"
  FileUtils.mkdir_p(File.dirname(override))
  File.write(override, "guard:\n  mode: \"off\"\n")
  puts "mode before: #{mode.call}"
  out, err, rc = run(guard, cwd: scratch, stdin: payload)
  puts "PreToolUse guard: rc=#{rc} stdout=#{out.inspect} stderr=#{err.inspect}"
  puts "baseline recorded by the PreToolUse call: #{File.file?(baseline)}"
  out, err, rc = run(guard + ["--after"], cwd: scratch, stdin: "")
  puts "PostToolUse guard --after: rc=#{rc} stdout=#{out.inspect}"
  puts "  stderr: #{err.strip}"
  puts "override still present after the check: #{File.file?(override)}"
  puts "mode after: #{mode.call}"
  puts "guard.log: #{File.file?(log) ? File.read(log).strip : '(none)'}"

  puts "\n== case B: SOFT_FOUNDRY_GUARD=off in the environment, override file says mode: \"warn\""
  FileUtils.rm_f(log)
  File.write(override, "guard:\n  mode: \"warn\"\n")
  env = { "SOFT_FOUNDRY_GUARD" => "off" }
  puts "mode before: #{mode.call} (file) / env off"
  out, err, rc = run(guard, cwd: scratch, stdin: payload, env: env)
  puts "PreToolUse guard: rc=#{rc} stderr=#{err.inspect}"
  puts "baseline recorded: #{File.file?(baseline)}"
  out, err, rc = run(guard + ["--after"], cwd: scratch, stdin: "", env: env)
  puts "PostToolUse guard --after: rc=#{rc}"
  puts "  stderr: #{err.strip}"
  puts "override still present after the check: #{File.file?(override)}"

  puts "\n== case C: SOFT_FOUNDRY_GUARD=off, no override, an uncommitted hand edit to the policy header"
  FileUtils.rm_f(log)
  FileUtils.rm_f(override)
  original = File.read(policy)
  File.write(policy, original.sub("version: 1", "version: 1\n# maintainer's uncommitted edit"))
  out, err, rc = run(guard, cwd: scratch, stdin: payload, env: env)
  puts "PreToolUse guard: rc=#{rc}; baseline recorded: #{File.file?(baseline)}"
  out, err, rc = run(guard + ["--after"], cwd: scratch, stdin: "", env: env)
  puts "PostToolUse guard --after: rc=#{rc}"
  puts "  stderr: #{err.strip}"
  puts "policy edit survived the check: #{File.read(policy).include?('uncommitted edit')}"
  File.write(policy, original)

  puts "\n== case D (control): override mode: \"warn\", no environment variable"
  FileUtils.rm_f(log)
  File.write(override, "guard:\n  mode: \"warn\"\n")
  out, err, rc = run(guard, cwd: scratch, stdin: payload)
  puts "PreToolUse guard: rc=#{rc}; baseline recorded: #{File.file?(baseline)}"
  out, err, rc = run(guard + ["--after"], cwd: scratch, stdin: "")
  puts "PostToolUse guard --after: rc=#{rc} stderr=#{err.inspect}"
  puts "override still present after the check: #{File.file?(override)}"
  puts "baseline consumed: #{!File.file?(baseline)}"

  puts "\n== case E (control): override mode: \"off\", but a baseline from an earlier warn-mode call still present (< 30 min)"
  FileUtils.rm_f(log)
  run(guard, cwd: scratch, stdin: payload) # warn mode: records a baseline that includes the warn override
  File.write(override, "guard:\n  mode: \"off\"\n") # the maintainer switches to off between calls
  out, err, rc = run(guard, cwd: scratch, stdin: payload)
  puts "PreToolUse guard (off): rc=#{rc}"
  out, err, rc = run(guard + ["--after"], cwd: scratch, stdin: "")
  puts "PostToolUse guard --after: rc=#{rc}"
  puts "  stderr: #{err.strip}"
  puts "override content after the check: #{File.file?(override) ? File.read(override).strip.inspect : '(deleted)'}"
end
puts "\nprobe exit=0"
