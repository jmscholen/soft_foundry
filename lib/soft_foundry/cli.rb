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
require_relative "errors"
require_relative "installer"

module SoftFoundry
  class CLI
    UPSTREAM = "https://github.com/jmscholen/soft_foundry"
    EXIT_TARGET = 1
    EXIT_CONFLICTS = 3
    EXIT_INTERNAL = 4

    def initialize(argv, out: $stdout, err: $stderr, root: Dir.pwd, source: nil)
      @argv = argv.dup
      @out = out
      @err = err
      @root = File.expand_path(root)
      @source = source
    end

    def run
      command = @argv.shift
      case command
      when "init" then init
      when "onboard" then Onboarding.new(@root, out: @out, source: @source).run && 0
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
    rescue InternalError => e
      @err.puts upstream_guidance(e)
      EXIT_INTERNAL
    rescue StandardError => e
      @err.puts "soft-foundry: #{e.message}"
      EXIT_TARGET
    end

    private

    def flag(name) = !!@argv.delete(name)

    def init
      dry_run = flag("--dry-run")
      force = flag("--force")
      no_onboard = flag("--no-onboard")
      allow_non_git = flag("--allow-non-git")
      root_given = option("--root")
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?

      root = resolve_root(root_given, allow_non_git)
      installer = Installer.new(root, source: @source || Installer::Source.packaged, force: force, allow_non_git: allow_non_git)
      plan = installer.plan
      @out.puts "root: #{root}"
      @out.puts "mode: dry run, nothing written" if dry_run
      plan.actions.each { |a| @out.puts format("%-9s %s%s", a.status, a.path, a.reason.empty? ? "" : "  (#{a.reason})") }
      plan.warnings.each { |w| @out.puts "warning: #{w}" }

      unless dry_run
        installer.apply(plan)
        errors = Check.new(ControlPlane.new(root)).run.select { |f| f.level == :error }
        if errors.empty?
          @out.puts "check: ok"
        elsif plan.clean
          raise InternalError.new("control-plane check failed immediately after a clean install", component: "control plane", diagnostic: errors.map(&:message))
        else
          @out.puts "check: failed, resolve the conflicts above and rerun"
          errors.each { |f| @out.puts "  #{f.message}" }
        end
        Onboarding.new(root, out: @out).run(providers_only: true) unless no_onboard
      end

      @out.puts "summary: #{plan.counts.map { |k, v| "#{k} #{v}" }.join(', ')}"
      plan.conflicts.positive? ? EXIT_CONFLICTS : 0
    rescue Error
      raise
    rescue StandardError => e
      raise InternalError.new("#{e.class}: #{e.message}", component: "installer", diagnostic: Array(e.backtrace).first(5))
    end

    def resolve_root(given, allow_non_git)
      candidate = File.expand_path(given || @root)
      raise TargetError, "#{candidate} is not a directory" unless File.directory?(candidate)
      return candidate if allow_non_git

      top = Git.new(candidate).toplevel
      raise TargetError, "#{candidate} is not inside a Git work tree; pass --allow-non-git to install anyway" unless top
      if given && File.realpath(candidate) != File.realpath(top)
        raise TargetError, "--root must be the repository top-level (#{top})"
      end
      top
    end

    def upstream_guidance(error)
      url = (Gem.loaded_specs["soft_foundry"]&.metadata || {}).fetch("source_code_uri", UPSTREAM)
      lines = ["soft-foundry: internal failure in #{error.component}: #{sanitize(error.message)}",
               "This is a defect in Soft Foundry #{SoftFoundry::VERSION}, not in your repository. Nothing further was changed."]
      unless error.diagnostic.empty?
        lines << "diagnostic:"
        error.diagnostic.each { |d| lines << "  #{sanitize(d)}" }
      end
      lines << "Help fix it upstream: fork #{url}, reproduce with the diagnostic above, and open a pull request or issue."
      lines << "  gh repo fork #{url.delete_prefix('https://github.com/')} --clone"
      lines.join("\n")
    end

    # Diagnostics stay repository-relative and free of home or gem paths.
    def sanitize(text)
      gem_root = File.expand_path("../..", __dir__)
      text.to_s.gsub(gem_root, "<soft-foundry>").gsub(@root, ".").gsub(Dir.home, "~").gsub(/[^ -~]/, "?")
    end

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
        ".ai/manifest.yml" => File.exist?(File.join(@root, Manifest::PATH)),
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
          soft-foundry init [options]             install the control plane into this repository, then onboard
              --dry-run  --force  --no-onboard  --root PATH  --allow-non-git
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
