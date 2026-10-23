# frozen_string_literal: true

require_relative "errors"
require_relative "shell"
require_relative "text"

module SoftFoundry
  # The process half of `phase run <phase> <phase>... --parallel`: the
  # per-run environment a person asked for, and starting every phase's
  # session at once and waiting for all of them.
  #
  # A value given with `--env` is passed only through the child's
  # environment (never an argument, never a file, never output): it may be
  # a credential, so every message that could carry it is redacted.
  class ParallelRun
    Outcome = Data.define(:launch, :status, :error)

    # NAME=VALUE pairs from `--env`, validated: the name matches
    # [A-Z_][A-Z0-9_]*, is not in the SOFT_FOUNDRY_ namespace, and is given
    # once. Messages name the variable and never echo a value.
    def self.parse_env(specs)
      specs.each_with_object({}) do |spec, env|
        name, sep, value = spec.to_s.partition("=")
        raise ArgumentError, "--env takes NAME=VALUE (a variable name, an equals sign, then its value; {phase} in the value becomes the phase id)" if sep.empty?
        Text.env_name!(name)
        raise ArgumentError, "environment variable #{name} is given twice; give each --env name once" if env.key?(name)
        raise ArgumentError, "the value of #{name} contains a NUL byte, which a process environment cannot carry" if value.include?("\0")
        env[name] = value
      end
    end

    # Each session gets its own value: `{phase}` is the phase id.
    def self.expand(env, phase_id)
      env.transform_values { |v| v.gsub("{phase}", phase_id) }
    end

    def initialize(root, runner: nil, resolver: Shell.method(:resolve))
      @root = File.expand_path(root)
      @runner = runner
      @resolver = resolver
      @pids = []
      @interrupted = false
    end

    attr_reader :interrupted

    # Starts every launch in its own thread and waits for all of them. One
    # failing (or failing to start) does not stop the others. An interrupt
    # or termination signal is forwarded to every child as TERM; the run
    # still waits for them and reports each. Returns outcomes in input order.
    def run(launches)
      outcomes = Array.new(launches.size)
      previous = %w[INT TERM].to_h { |sig| [sig, Signal.trap(sig) { interrupt! }] }
      threads = launches.each_with_index.map do |launch, i|
        Thread.new do
          outcomes[i] = begin
            Outcome.new(launch: launch, status: Integer(@runner ? @runner.call(launch) : spawn_and_wait(launch)), error: nil)
          rescue StandardError => e
            Outcome.new(launch: launch, status: 1, error: redact(e.message, launch))
          end
        end
      end
      threads.each(&:join)
      outcomes
    ensure
      previous&.each { |sig, handler| Signal.trap(sig, handler) }
    end

    private

    # Runs in signal context: no locks, no output.
    def interrupt!
      @interrupted = true
      @pids.dup.each do |pid|
        Process.kill("TERM", pid)
      rescue SystemCallError
        nil
      end
    end

    def spawn_and_wait(launch)
      executable = @resolver.call(launch.executable)
      pid = Process.spawn(launch.env, executable, *launch.args, chdir: @root)
      @pids << pid
      begin
        Process.kill("TERM", pid) if @interrupted
        _, status = Process.wait2(pid)
      ensure
        @pids.delete(pid)
      end
      status.exitstatus || (status.termsig ? 128 + status.termsig : 1)
    end

    def redact(message, launch)
      launch.env.reject { |name, _| name.start_with?(Text::RESERVED_ENV_PREFIX) }.values.reject(&:empty?).reduce(message.to_s) { |text, value| text.gsub(value, "[hidden]") }.lines.first.to_s.strip
    end
  end
end
