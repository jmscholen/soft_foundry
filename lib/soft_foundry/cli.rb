# frozen_string_literal: true

require "yaml"
require_relative "onboarding"
require_relative "shell"
require_relative "git"
require_relative "control_plane"
require_relative "change_record"
require_relative "gate"
require_relative "check"
require_relative "hooks"

module SoftFoundry
  class CLI
    def initialize(argv, out: $stdout, err: $stderr, root: Dir.pwd)
      @argv = argv.dup
      @out = out
      @err = err
      @root = File.expand_path(root)
    end

    def run
      command = @argv.shift
      case command
      when "init", "onboard" then Onboarding.new(@root, out: @out).run && 0
      when "models" then models
      when "doctor" then doctor
      when "check" then check
      when "change" then change
      when "gate" then gate
      when "ci" then ci
      when "hooks" then hooks
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

    def plane = @plane ||= ControlPlane.new(@root)
    def git = @git ||= Git.new(@root)

    def option(name)
      index = @argv.index(name)
      return nil unless index
      @argv.delete_at(index)
      @argv.delete_at(index) or raise ArgumentError, "#{name} requires a value"
    end

    def models
      path = File.join(@root, ".soft-foundry", "runtime.yml")
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
        "git repository" => git.repository?,
        "AGENTS.md" => File.exist?(File.join(@root, "AGENTS.md")),
        ".ai/README.md" => File.exist?(File.join(@root, ".ai/README.md")),
        ".ai/workflow.yml" => File.exist?(File.join(@root, ".ai/workflow.yml")),
        ".ai/paths.yml" => File.exist?(File.join(@root, ".ai/paths.yml")),
        "control plane check" => plane.present? && Check.new(plane).run.none? { |f| f.level == :error },
        "pre-commit hook" => File.exist?(File.join(@root, ".git/hooks/pre-commit")) && File.read(File.join(@root, ".git/hooks/pre-commit")).include?(Hooks::MARKER),
        "local runtime" => File.exist?(File.join(@root, ".soft-foundry/runtime.yml"))
      }
      checks.each { |name, ok| @out.puts "#{ok ? '✓' : '✗'} #{name}" }
      checks.values.all? ? 0 : 2
    end

    def check
      findings = Check.new(plane).run
      findings.each { |f| @out.puts "#{f.level == :error ? '✗' : '!'} #{f.message}" }
      errors = findings.count { |f| f.level == :error }
      @out.puts(errors.zero? ? "✓ control plane: #{plane.phases.size} phases, #{plane.skill_names.size} skills, no errors" : "✗ control plane: #{errors} error(s)")
      errors.zero? ? 0 : 2
    end

    def change
      sub = @argv.shift
      case sub
      when "new"
        slug = @argv.shift or raise ArgumentError, "Usage: soft-foundry change new <slug> [--title TITLE] [--branch BRANCH]"
        title = option("--title")
        branch = option("--branch") || (git.repository? ? git.branch : nil)
        record = ChangeRecord.create(@root, slug, control_plane: plane, title: title, branch: branch, worktree: @root)
        @out.puts "created #{relative(record.dir)} with #{plane.phases.size} phase directories"
        @out.puts "branch: #{branch || slug}"
        0
      when "status"
        status(@argv.shift || current_slug)
      when "list"
        list_changes.each { |slug| @out.puts slug }
        0
      else
        @err.puts "Usage: soft-foundry change <new|status|list>"
        1
      end
    end

    def status(slug)
      record = load_record(slug)
      meta = record.metadata
      @out.puts "#{slug}: #{meta.dig('change', 'title')}  [status: #{meta['status']}, phase: #{meta['current_phase']}, risk: #{meta['risk']}]"
      results = Gate.new(record, git: git).evaluate_all
      results.each { |r| @out.puts format("  %-22s %-12s %s", r.phase.output, r.status, summarize(r)) }
      results.any?(&:failed?) ? 2 : 0
    end

    def gate
      target = @argv.shift or raise ArgumentError, "Usage: soft-foundry gate <phase|all> [--change SLUG]"
      slug = option("--change") || current_slug
      record = load_record(slug)
      gate = Gate.new(record, git: git)
      results = target == "all" ? gate.evaluate_all : [gate.evaluate(target)]
      results.each { |r| print_result(r) }
      results.any?(&:failed?) ? 2 : 0
    end

    def ci
      code = check
      list_changes.each do |slug|
        @out.puts "\nchange #{slug}"
        results = Gate.new(load_record(slug), git: git).evaluate_all
        results.reject(&:skipped?).each { |r| print_result(r) }
        code = 2 if results.any?(&:failed?)
      end
      @out.puts(code.zero? ? "\n✓ ci passed" : "\n✗ ci failed")
      code
    end

    def hooks
      raise ArgumentError, "Usage: soft-foundry hooks install" unless @argv.shift == "install"
      @out.puts "installed #{relative(Hooks.install(@root))}"
      0
    end

    def print_result(result)
      @out.puts "#{result.phase.output}  #{result.status}  #{result.failed? ? 'FAIL' : (result.skipped? ? 'SKIP' : 'PASS')}"
      result.checks.each do |c|
        mark = { pass: "✓", fail: "✗", warn: "!", skip: "-" }.fetch(c.outcome)
        @out.puts "  #{mark} #{c.name}#{c.detail.to_s.empty? ? '' : ": #{c.detail}"}"
      end
    end

    def summarize(result)
      return "" if result.skipped?
      return "FAIL: #{result.checks.select { |c| c.outcome == :fail }.map(&:name).join(', ')}" if result.failed?
      "ok"
    end

    def current_slug
      raise "not a git repository; pass --change SLUG" unless git.repository?
      branch = git.branch
      slug = branch.to_s.sub(%r{\Achange/}, "")
      candidates = [branch, slug].compact.uniq
      found = candidates.find { |c| File.exist?(File.join(@root, "changes", c.to_s, "metadata.yml")) }
      found or raise "no change record for branch '#{branch}'; run `soft-foundry change new <slug>` or pass --change SLUG"
    end

    def load_record(slug)
      record = ChangeRecord.new(@root, slug, control_plane: plane)
      raise "no change record at #{relative(record.dir)}" unless record.exists?
      record
    end

    def list_changes
      base = File.join(@root, "changes")
      return [] unless File.directory?(base)
      Dir.glob("**/metadata.yml", base: base).map { |p| File.dirname(p) }.sort
    end

    def relative(path)
      path.delete_prefix("#{@root}/")
    end

    def help
      @out.puts <<~TEXT
        Soft Foundry #{SoftFoundry::VERSION}

        Usage:
          soft-foundry init                       bootstrap/onboard the current repository
          soft-foundry onboard                    discover providers and repair agent adapters
          soft-foundry doctor                     validate repository bootstrap
          soft-foundry check                      lint the .ai/ control plane
          soft-foundry change new <slug>          create changes/<slug>/ from phase templates
          soft-foundry change status [slug]       show phase status and gate results
          soft-foundry change list                list change records
          soft-foundry gate <phase|all> [--change SLUG]
                                                  evaluate a phase's completion gate
          soft-foundry ci                         check + gate every change record (used by CI and pre-commit)
          soft-foundry hooks install              install the pre-commit hook
          soft-foundry models                     show locally accessible models
          soft-foundry shell claude|codex|grok    launch a coding shell in this repository
          soft-foundry version

        `AGENTS.md` and `.ai/` are canonical. Vendor files such as `CLAUDE.md` only point to them.
      TEXT
    end
  end
end
