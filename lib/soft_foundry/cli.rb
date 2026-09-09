# frozen_string_literal: true

require "yaml"
require_relative "onboarding"
require_relative "shell"

module SoftFoundry
  class CLI
    def initialize(argv, out: $stdout, err: $stderr)
      @argv = argv.dup
      @out = out
      @err = err
    end

    def run
      command = @argv.shift
      case command
      when "init", "onboard"
        Onboarding.new(Dir.pwd, out: @out).run
        0
      when "models"
        models
      when "doctor"
        doctor
      when "shell"
        shell_name = @argv.shift or raise ArgumentError, "Usage: soft-foundry shell <claude|codex|grok> [args...]"
        Shell.launch(shell_name, @argv)
        0
      when "version", "--version", "-v"
        @out.puts SoftFoundry::VERSION
        0
      else
        help
        command.nil? ? 0 : 1
      end
    rescue StandardError => e
      @err.puts "soft-foundry: #{e.message}"
      1
    end

    private

    def models
      path = File.join(Dir.pwd, ".soft-foundry", "runtime.yml")
      raise "No local runtime inventory. Run `soft-foundry onboard` first." unless File.exist?(path)
      data = YAML.safe_load_file(path)
      data.fetch("providers", {}).each do |name, provider|
        @out.puts "#{name}:"
        if provider["configured"]
          Array(provider["models"]).each { |model| @out.puts "  - #{model}" }
          @out.puts "  ! #{provider['error']}" if provider["error"]
        else
          @out.puts "  (not configured)"
        end
      end
      0
    end

    def doctor
      checks = {
        "AGENTS.md" => File.exist?("AGENTS.md"),
        ".ai/README.md" => File.exist?(".ai/README.md"),
        ".ai/workflow.yml" => File.exist?(".ai/workflow.yml"),
        "local runtime" => File.exist?(".soft-foundry/runtime.yml")
      }
      checks.each { |name, ok| @out.puts "#{ok ? '✓' : '✗'} #{name}" }
      checks.values.all? ? 0 : 2
    end

    def help
      @out.puts <<~TEXT
        Soft Foundry #{SoftFoundry::VERSION}

        Usage:
          soft-foundry init                 bootstrap/onboard the current repository
          soft-foundry onboard              discover providers and repair agent adapters
          soft-foundry models               show locally accessible models
          soft-foundry doctor               validate repository bootstrap
          soft-foundry shell claude [...]   launch Claude Code in this repository
          soft-foundry shell codex [...]    launch Codex in this repository
          soft-foundry shell grok [...]     launch a Grok CLI when installed
          soft-foundry version

        `AGENTS.md` and `.ai/` are canonical. Vendor files such as `CLAUDE.md` only point to them.
      TEXT
    end
  end
end
