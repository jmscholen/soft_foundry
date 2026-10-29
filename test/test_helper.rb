# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"
require_relative "../lib/soft_foundry"

module FoundryFixture
  REPO_ROOT = File.expand_path("..", __dir__)

  # A throwaway git repository carrying a copy of this repo's .ai/ control plane.
  def with_fixture_repo
    Dir.mktmpdir("soft-foundry") do |dir|
      FileUtils.cp_r(File.join(REPO_ROOT, ".ai"), dir)
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "lib", "app.rb"), "puts 1\n")
      File.write(File.join(dir, "AGENTS.md"), "# agents\n")
      sh(dir, "git", "init", "-q", "-b", "main")
      configure_git(dir)
      sh(dir, "git", "add", ".")
      sh(dir, "git", "commit", "-q", "-m", "initial")
      yield dir
    end
  end

  # A throwaway git repository with only an application file: an init target.
  def with_target_repo(git: true)
    Dir.mktmpdir("soft-foundry-target") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "lib", "app.rb"), "puts 1\n")
      if git
        sh(dir, "git", "init", "-q", "-b", "main")
        configure_git(dir)
        sh(dir, "git", "add", ".")
        sh(dir, "git", "commit", "-q", "-m", "initial")
      end
      yield File.realpath(dir)
    end
  end

  # Identity for commits, and no automatic gc: a detached background gc
  # can still be writing .git/objects/maintenance.lock while mktmpdir is
  # deleting the directory, which raised ENOENT at random on CI.
  def configure_git(dir)
    sh(dir, "git", "config", "user.email", "test@example.com")
    sh(dir, "git", "config", "user.name", "Test")
    sh(dir, "git", "config", "gc.auto", "0")
    sh(dir, "git", "config", "gc.autoDetach", "false")
    sh(dir, "git", "config", "maintenance.auto", "false")
  end

  def source = SoftFoundry::Installer::Source.new(REPO_ROOT)

  def init(dir, *args, env: {}, src: source)
    out = StringIO.new
    err = StringIO.new
    code = nil
    with_env(env) { code = SoftFoundry::CLI.new(["init", "--no-onboard", *args], out: out, err: err, root: dir, source: src).run }
    [code, out.string + err.string]
  end

  def with_env(env)
    saved = env.to_h { |k, _| [k, ENV[k]] }
    env.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  def commit_all(dir, msg = "wip")
    sh(dir, "git", "add", "-A")
    sh(dir, "git", "commit", "-q", "-m", msg)
  end

  def sh(dir, *cmd)
    out, err, status = Open3.capture3(*cmd, chdir: dir)
    raise "#{cmd.join(' ')} failed: #{err}" unless status.success?
    out
  end

  def head(dir) = sh(dir, "git", "rev-parse", "HEAD").strip

  # Variables a phase session or a developer's shell may carry that would
  # change what a command does under test: cleared for every invocation
  # the suite builds, so the suite passes wherever it is run (REQ-024).
  SESSION_ENV = { "SOFT_FOUNDRY_PHASE" => nil, "SOFT_FOUNDRY_PARALLEL" => nil, "SOFT_FOUNDRY_GUARD" => nil, "SOFT_FOUNDRY_BILLING" => nil,
                  "ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil, "OPENROUTER_API_KEY" => nil, "GEMINI_API_KEY" => nil }.freeze
  # Scrubbed once when the suite loads, so a test that sets one of them
  # deliberately (with_env) still wins inside its block.
  SESSION_ENV.each_key { |k| ENV.delete(k) }

  def cli(dir, *args, **opts)
    out = StringIO.new
    err = StringIO.new
    code = SoftFoundry::CLI.new(args, out: out, err: err, root: dir, **opts).run
    [code, out.string + err.string]
  end

  # The one phase-completion fixture, shared with the harness evals so a
  # planted record means the same thing in both (HarnessEval.complete_phase!).
  # `runner: false` leaves executed_by alone, for tests about phases
  # completed outside `phase run`.
  def complete_phase!(record, phase_id, sha:, fill: true, runner: true)
    SoftFoundry::HarnessEval.complete_phase!(record, phase_id, sha, fill: fill, runner: runner)
  end
end
