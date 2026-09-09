# frozen_string_literal: true

require "fileutils"
require "yaml"
require_relative "providers"
require_relative "installer"
require_relative "safe_write"

module SoftFoundry
  # Runtime onboarding: repair adapter files and discover model providers.
  # `init` runs this after installation with providers_only: true.
  class Onboarding
    LOCAL_DIR = ".soft-foundry"

    def initialize(root = Dir.pwd, out: $stdout, source: nil)
      @root = File.expand_path(root)
      @out = out
      @source = source
    end

    def run(providers_only: false)
      repair_adapters unless providers_only
      results = Providers.all.map(&:discover)
      write_runtime(results)
      print_results(results)
      results
    end

    private

    def repair_adapters
      installer = Installer.new(@root, source: @source || Installer::Source.packaged)
      actions = installer.adapter_actions
      installer.write_actions(actions)
      actions.each { |a| @out.puts format("%-9s %s%s", a.status, a.path, a.reason.empty? ? "" : "  (#{a.reason})") }
    end

    def write_runtime(results)
      dir = File.join(@root, LOCAL_DIR)
      SafeWrite.ensure_directory!(dir)
      payload = {
        "version" => 1,
        "providers" => results.to_h do |result|
          [result.name, { "configured" => result.configured, "models" => result.models, "error" => result.error }]
        end
      }
      SafeWrite.write(File.join(dir, "runtime.yml"), YAML.dump(payload))
    end

    def print_results(results)
      @out.puts "\nLLM provider discovery"
      results.each do |result|
        status = if !result.configured then "not configured (set #{result.api_key_env})" elsif result.error then "error: #{Provider.sanitize(result.error)}" else "#{result.models.length} models" end
        @out.puts format("%-10s %s", result.name, status)
      end
      @out.puts "\nLocal model inventory written to #{LOCAL_DIR}/runtime.yml (gitignored)."
    end
  end
end
