# frozen_string_literal: true

require "open3"
require "yaml"
require_relative "errors"

module SoftFoundry
  # Agentic maturity assessment: shells into an installed `claude` CLI to run
  # the real repository-discovery skill, with actual judgment a deterministic
  # scan cannot produce. Costs real tokens/subscription usage. Best-effort:
  # the exact flags a non-interactive Claude Code invocation needs can vary
  # by installed version, so failures are reported plainly rather than
  # silently swallowed or treated as a crash.
  class MaturityDeepAssess
    Result = Data.define(:ok, :message)

    TIMEOUT_SECONDS = 900

    PROMPT = <<~PROMPT
      You are running the Soft Foundry `repository-discovery` skill in
      non-interactive mode, invoked directly by `soft-foundry onboard
      --maturity=deep` rather than as part of a specific change.

      Read AGENTS.md, .ai/README.md, .ai/maturity.yml, and
      .ai/skills/repository-discovery/SKILL.md and permissions.yml.

      Assess THIS repository's current state (not a specific change) against
      every capability .ai/maturity.yml requires. Distinguish discovered
      facts, inferred facts, and unknowns; do not guess. Follow
      .ai/maturity.yml's assessment_rules exactly: UNKNOWN unless absence is
      conclusively established, EXTERNAL only with an identified ownership
      boundary, NOT_APPLICABLE only with an explicit rationale.

      Compute the resulting maturity level and gaps using the scoring rule
      in .ai/maturity.yml (highest contiguous level with every required
      capability at a satisfied status).

      Write the complete result directly to .ai/repository.yml, matching the
      schema shown in that file's own comments (repository, technology,
      infrastructure, capabilities, maturity). Set repository.assessed to
      true, repository.assessed_at to the current UTC time, repository.
      commit_sha to the current HEAD, and repository.assessed_by to
      "soft-foundry onboard --maturity=deep". This is the one file
      repository-discovery may write outside a change directory, per its own
      permissions.yml.

      Do not modify any other file. When finished, print a one-line summary
      of the resulting maturity level and exit.
    PROMPT

    def self.available?(binary: "claude")
      ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, binary)) }
    end

    def initialize(root, binary: "claude", runner: nil, timeout: TIMEOUT_SECONDS)
      @root = File.expand_path(root)
      @binary = binary
      @timeout = timeout
      @runner = runner || method(:real_run)
    end

    def run!
      raise TargetError, "#{@binary} is not installed or not on PATH; deep maturity assessment requires it (see `soft-foundry shell claude`)" unless self.class.available?(binary: @binary)

      before = File.exist?(manifest_path = File.join(@root, ".ai", "repository.yml")) ? File.mtime(manifest_path) : nil
      status, output = @runner.call([@binary, "-p", PROMPT], @root, @timeout)
      if status.nil?
        return Result.new(ok: false, message: "#{@binary} timed out after #{@timeout}s; no changes made to .ai/repository.yml")
      end
      unless status
        return Result.new(ok: false, message: "#{@binary} exited with a non-zero status. Output:\n#{output}")
      end
      unless File.exist?(manifest_path)
        return Result.new(ok: false, message: "#{@binary} exited but .ai/repository.yml was not written. Output:\n#{output}")
      end
      after = File.mtime(manifest_path)
      if before && after == before
        return Result.new(ok: false, message: "#{@binary} exited but .ai/repository.yml was not updated. Output:\n#{output}")
      end
      Result.new(ok: true, message: "deep assessment complete: #{output.lines.last&.strip}")
    end

    private

    # Returns [success_boolean, combined_output]. Real subprocess, argv-only
    # (no shell interpolation of the prompt, so its content can never be
    # interpreted as shell syntax). `wait_thr.join(timeout)` blocks up to
    # `timeout` seconds and returns the thread if the process exited in
    # time, or nil if it is still running - only then is `.value` safe to
    # call without blocking again.
    def real_run(argv, dir, timeout)
      Open3.popen2e(*argv, chdir: dir) do |_in, out_err, wait_thr|
        if wait_thr.join(timeout)
          [wait_thr.value.success?, out_err.read]
        else
          begin
            Process.kill("TERM", wait_thr.pid)
          rescue Errno::ESRCH, Errno::EPERM
            nil
          end
          wait_thr.join(2)
          [nil, ""]
        end
      end
    rescue StandardError => e
      [false, "#{e.class}: #{e.message}"]
    end
  end
end
