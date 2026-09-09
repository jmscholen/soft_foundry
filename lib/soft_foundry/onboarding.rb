# frozen_string_literal: true

require "fileutils"
require "yaml"
require_relative "providers"
require_relative "agent_files"

module SoftFoundry
  class Onboarding
    LOCAL_DIR = ".soft-foundry"

    def initialize(root = Dir.pwd, out: $stdout)
      @root = File.expand_path(root)
      @out = out
    end

    def run
      ensure_local_ignore
      agents = AgentFiles.new(@root)
      report_file("AGENTS.md", agents.ensure_agents!)
      report_file("CLAUDE.md", agents.ensure_claude!)

      results = Providers.all.map(&:discover)
      write_runtime(results)
      print_results(results)
      results
    end

    private

    def ensure_local_ignore
      path = File.join(@root, ".gitignore")
      body = File.exist?(path) ? File.read(path) : ""
      return if body.lines.map(&:strip).include?("#{LOCAL_DIR}/")
      File.open(path, "a") { |f| f.write("\n#{LOCAL_DIR}/\n") }
    end

    def write_runtime(results)
      dir = File.join(@root, LOCAL_DIR)
      FileUtils.mkdir_p(dir)
      payload = {
        "version" => 1,
        "providers" => results.to_h do |result|
          [result.name, { "configured" => result.configured, "models" => result.models, "error" => result.error }]
        end
      }
      File.write(File.join(dir, "runtime.yml"), YAML.dump(payload))
    end

    def print_results(results)
      @out.puts "\nLLM provider discovery"
      results.each do |result|
        status = if !result.configured then "not configured" elsif result.error then "error: #{result.error}" else "#{result.models.length} models" end
        @out.puts format("%-10s %s", result.name, status)
      end
      @out.puts "\nLocal model inventory written to #{LOCAL_DIR}/runtime.yml (gitignored)."
    end

    def report_file(name, status)
      @out.puts format("%-12s %s", name, status)
    end
  end
end
