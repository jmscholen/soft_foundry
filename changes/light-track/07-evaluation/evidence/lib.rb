# frozen_string_literal: true

# Shared helpers for the evaluation journeys. Every observation a journey
# asserts on comes from the worktree's CLI run as a separate process in a
# throwaway repository, the way a person or an agent runs it. The library
# is loaded only to plant record states (the phase-completion fixture the
# test suite and the harness evals share).
#
# Usage: ruby <journey>.rb <repository root of the change under evaluation>
require "tmpdir"
require "fileutils"
require "open3"
require "yaml"

ROOT = File.expand_path(ARGV.fetch(0))
require File.join(ROOT, "lib", "soft_foundry")

CLEARED = %w[SOFT_FOUNDRY_PHASE SOFT_FOUNDRY_PARALLEL SOFT_FOUNDRY_GUARD SOFT_FOUNDRY_BILLING ANTHROPIC_API_KEY OPENAI_API_KEY XAI_API_KEY OPENROUTER_API_KEY GEMINI_API_KEY].freeze
$failures = 0
$asserts = 0

def say(text = "") = puts(text)

def sh(dir, *cmd)
  out, err, status = Open3.capture3(*cmd, chdir: dir)
  raise "#{cmd.join(' ')} failed: #{err}" unless status.success?
  out
end

# Runs the worktree's CLI in `dir` with colour off and no terminal, prints
# the command, its output with the temporary directory replaced, and the
# exit status. Returns [exit status, output].
def sf(dir, *args, quiet: false)
  env = CLEARED.to_h { |k| [k, nil] }.merge("NO_COLOR" => "1")
  out, status = Open3.capture2e(env, "ruby", "-I#{File.join(ROOT, 'lib')}", File.join(ROOT, "exe", "soft-foundry"), *args, chdir: dir)
  shown = out.gsub(File.realpath(dir), "<repo>").gsub(dir, "<repo>")
  say "$ soft-foundry #{args.join(' ')}"
  say(quiet ? "  (#{shown.lines.size} lines, not shown)" : shown.lines.map { |l| "  #{l}" }.join)
  say "  [exit #{status.exitstatus}]"
  [status.exitstatus, out]
end

def expect(description, condition)
  $asserts += 1
  $failures += 1 unless condition
  say "assert #{condition ? 'pass' : 'FAIL'}: #{description}"
  condition
end

def step(text) = say("\n## #{text}")

def with_repo
  Dir.mktmpdir("sf-eval") do |dir|
    FileUtils.cp_r(File.join(ROOT, ".ai"), dir)
    FileUtils.mkdir_p(File.join(dir, "lib"))
    File.write(File.join(dir, "lib", "app.rb"), "puts 1\n")
    File.write(File.join(dir, "AGENTS.md"), "# agents\n")
    # As in a repository the tool is installed in: machine-local state is ignored.
    File.write(File.join(dir, ".gitignore"), ".soft-foundry/\n")
    sh(dir, "git", "init", "-q", "-b", "main")
    [%w[user.email eval@example.com], %w[user.name Evaluator], %w[gc.auto 0], %w[maintenance.auto false]].each { |k, v| sh(dir, "git", "config", k, v) }
    commit(dir, "initial")
    yield dir
  end
end

def commit(dir, message)
  sh(dir, "git", "add", "-A")
  sh(dir, "git", "commit", "-q", "-m", message)
end

def head(dir) = sh(dir, "git", "rev-parse", "HEAD").strip
def plane(dir) = SoftFoundry::ControlPlane.new(dir)
def record(dir, slug) = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: plane(dir))

def set_metadata(dir, slug)
  path = File.join(dir, "changes", slug, "metadata.yml")
  data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true)
  yield data
  File.write(path, YAML.dump(data))
end

# What the agent does in a phase, reduced to its record: the phase's
# template files filled in and its handoff marked complete at HEAD.
def do_phase(dir, slug, phase)
  SoftFoundry::HarnessEval.complete_phase!(record(dir, slug), phase, head(dir))
end

def failing_checks(out) = out.lines.select { |l| l =~ /^\s*\S+ fail / }.map(&:strip)

def finish(name)
  say "\nsummary: #{name}: #{$asserts} assertions, #{$failures} failed"
  exit($failures.zero? ? 0 : 1)
end
