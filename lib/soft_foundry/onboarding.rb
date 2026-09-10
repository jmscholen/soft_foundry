# frozen_string_literal: true

require "fileutils"
require "yaml"
require_relative "providers"
require_relative "installer"
require_relative "control_plane"
require_relative "maturity_scan"
require_relative "maturity_deep_assess"
require_relative "errors"
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

    def run(providers_only: false, maturity: "scan", reassess: false)
      repair_adapters unless providers_only
      assess_maturity(mode: maturity, reassess: reassess) unless maturity == "off"
      results = Providers.all.map(&:discover)
      write_runtime(results)
      print_results(results)
      results
    end

    # Public so init can assess maturity independent of --no-onboard, which
    # only concerns provider discovery (a network operation); maturity's
    # scan mode is offline and has nothing to do with that flag.
    def assess_maturity(mode:, reassess:)
      plane = ControlPlane.new(@root)
      unless plane.present?
        @out.puts "maturity: .ai/ is not installed here; run `soft-foundry init` first"
        return
      end
      repo_path = File.join(@root, ".ai", "repository.yml")
      already = File.exist?(repo_path) && (YAML.safe_load_file(repo_path, permitted_classes: [Time, Date])["repository"] || {})["assessed"]
      if already && !reassess
        level = (YAML.safe_load_file(repo_path, permitted_classes: [Time, Date])["maturity"] || {})["current_id"]
        @out.puts "maturity: already assessed (#{level || 'unknown level'}); skipping. Use --reassess to force."
        return
      end

      case mode
      when "scan"
        result = MaturityScan.new(@root, control_plane: plane).run!
        @out.puts "maturity: scanned - level #{result['current_level']} (#{result['current_id']}), #{result['gaps'].size} gap(s) to the next level. Run with --maturity=deep for a judgment-based assessment."
      when "deep"
        result = MaturityDeepAssess.new(@root).run!
        @out.puts "maturity: #{result.ok ? result.message : "deep assessment failed: #{result.message}"}"
      else
        raise ArgumentError, "unknown --maturity mode '#{mode}' (expected scan, deep, or off)"
      end
    rescue TargetError => e
      @out.puts "maturity: #{e.message}"
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
