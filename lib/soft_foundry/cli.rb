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
require_relative "provider"
require_relative "budget"
require_relative "billing"
require_relative "updater"
require_relative "pr_discharge"
require_relative "advisory"
require_relative "guard"
require_relative "phase_runner"
require_relative "learning"

module SoftFoundry
  class CLI
    UPSTREAM = "https://github.com/jmscholen/soft_foundry"
    EXIT_TARGET = 1
    EXIT_CONFLICTS = 3
    EXIT_INTERNAL = 4

    def initialize(argv, out: $stdout, err: $stderr, input: $stdin, root: Dir.pwd, source: nil, updater: nil, pr_discharge: nil, shell: nil, runner: nil)
      @argv = argv.dup
      @out = out
      @err = err
      @input = input
      @root = File.expand_path(root)
      @source = source
      @updater = updater
      @pr_discharge = pr_discharge
      @shell = shell
      @runner = runner
    end

    def run
      command = @argv.shift
      case command
      when "init" then init
      when "onboard" then onboard
      when "models" then models
      when "doctor" then doctor
      when "check" then check
      when "change" then change
      when "budget" then budget
      when "gate" then gate
      when "ci" then ci
      when "hooks" then hooks
      when "guard" then guard
      when "phase" then phase
      when "learn" then learn
      when "update" then update
      when "shell"
        shell_name = @argv.shift or raise ArgumentError, "Usage: soft-foundry shell <claude|codex|grok> [args...]"
        # The shell is where model spend actually happens, so say how it is
        # paid for before handing the terminal over.
        billing_notice(shell: shell_name) if Shell::COMMANDS.key?(shell_name)
        # Shell.launch exec()s, which discards anything still sitting in a
        # buffered stdout, so the notice has to be pushed out first.
        @out.flush
        @err.flush
        (@shell || Shell.method(:launch)).call(shell_name, @argv)
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

    MATURITY_MODES = %w[scan deep off].freeze

    def onboard
      maturity = option("--maturity") || "scan"
      reassess = flag("--reassess")
      raise TargetError, "unknown --maturity mode '#{maturity}' (expected #{MATURITY_MODES.join(', ')})" unless MATURITY_MODES.include?(maturity)
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?
      billing_notice(shell: maturity == "deep" ? "claude" : nil)
      Onboarding.new(@root, out: @out, source: @source).run(maturity:, reassess:) && 0
    end

    def init
      dry_run = flag("--dry-run")
      force = flag("--force")
      no_onboard = flag("--no-onboard")
      allow_non_git = flag("--allow-non-git")
      root_given = option("--root")
      maturity = option("--maturity") || "scan"
      reassess = flag("--reassess")
      raise TargetError, "unknown --maturity mode '#{maturity}' (expected #{MATURITY_MODES.join(', ')})" unless MATURITY_MODES.include?(maturity)
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?

      root = resolve_root(root_given, allow_non_git)
      @resolved_root = root
      installer = Installer.new(root, source: @source || Installer::Source.packaged, force: force, allow_non_git: allow_non_git)
      plan = installer.plan
      @out.puts "root: #{root}"
      @out.puts "mode: dry run, nothing written" if dry_run
      plan.actions.each { |a| @out.puts format("%-9s %s%s", a.status, a.path, a.reason.empty? ? "" : "  (#{a.reason})") }
      plan.warnings.each { |w| @out.puts "warning: #{w}" }

      unless dry_run
        installer.apply(plan)
        @applied = true
        errors = begin
          Check.new(ControlPlane.new(root)).run.select { |f| f.level == :error }
        rescue StandardError => e
          [Check::Finding.new(:error, "control plane unreadable: #{e.message}")]
        end
        if errors.empty?
          @out.puts "check: ok"
        elsif plan.clean
          raise InternalError.new("control-plane check failed immediately after a clean install", component: "control plane", diagnostic: errors.map(&:message))
        else
          @out.puts "check: failed, resolve the conflicts above and rerun"
          errors.each { |f| @out.puts "  #{f.message}" }
        end
        # Maturity assessment is independent of --no-onboard: --no-onboard
        # only opts out of provider discovery (a network operation), and
        # scan mode is offline. --maturity=off is the way to skip it.
        onboarding = Onboarding.new(root, out: @out)
        billing_notice(shell: maturity == "deep" ? "claude" : nil, root: root)
        onboarding.assess_maturity(mode: maturity, reassess:) unless maturity == "off"
        onboarding.run(providers_only: true, maturity: "off") unless no_onboard
      end

      @out.puts "summary: #{plan.counts.map { |k, v| "#{k} #{v}" }.join(', ')}"
      if plan.conflicts.positive?
        @out.puts "conflicts: #{plan.actions.select { |a| a.status == 'conflict' }.map(&:path).join(', ')}"
        @out.puts "next: compare with `git diff`, keep your version, or commit it and rerun with --force to take the canonical version (uncommitted edits are never overwritten)"
        return EXIT_CONFLICTS
      end
      0
    rescue Error
      raise
    rescue StandardError => e
      raise InternalError.new("#{e.class}: #{e.message}", component: "installer", diagnostic: Array(e.backtrace).first(5))
    end

    def resolve_root(given, allow_non_git)
      candidate = File.expand_path(given || @root)
      raise TargetError, "#{candidate} is not a directory" unless File.directory?(candidate)
      raise TargetError, "refusing to install into the filesystem root" if candidate == "/"
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
               "This is a defect in Soft Foundry #{SoftFoundry::VERSION}, not in your repository. " +
               (@applied ? "Files reported above were written before the failure; review them with `git status`." : "Nothing was changed.")]
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
      out = text.to_s.gsub(gem_root, "<soft-foundry>")
      [@resolved_root, @root].compact.uniq.each { |r| out = out.gsub(r, ".") }
      home = begin
        Dir.home
      rescue StandardError
        nil
      end
      out = out.gsub(home, "~") if home && !home.empty? && home != "/"
      out.gsub(/[^ -~]/, "?")
    end

    def plane = @plane ||= ControlPlane.new(@root)
    def git = @git ||= Git.new(@root)

    def option(name)
      index = @argv.index(name)
      return nil unless index
      @argv.delete_at(index)
      @argv.delete_at(index) or raise TargetError, "#{name} requires a value"
    end

    # Every occurrence of a repeatable option, e.g. multiple --confirm ID.
    def options(name)
      values = []
      values << option(name) while @argv.include?(name)
      values
    end

    def models
      path = File.join(@root, ".soft-foundry", "runtime.yml")
      raise "No local runtime inventory. Run `soft-foundry onboard` first." unless File.exist?(path)
      data = YAML.safe_load_file(path)
      data.fetch("providers", {}).each do |name, provider|
        @out.puts "#{name}:"
        if provider["configured"]
          Array(provider["models"]).each { |model| @out.puts "  - #{Provider.sanitize(model)}" }
          @out.puts "  ! #{Provider.sanitize(provider['error'])}" if provider["error"]
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
        "claude guard hook" => !Hooks.claude_installed?(@root).nil?,
        "local runtime" => File.exist?(File.join(@root, ".soft-foundry/runtime.yml"))
      }
      mode, source = Guard.mode(@root)
      detail = { "claude guard hook" => " (mode: #{mode}, #{source})#{checks['claude guard hook'] ? '' : '; install with `soft-foundry hooks install --claude`'}" }
      checks.each { |name, ok| @out.puts "#{ok ? '✓ pass' : '✗ fail'} #{name}#{detail[name]}" }
      checks.values.all? ? 0 : 2
    end

    def check
      findings = Check.new(plane).run
      findings.each { |f| @out.puts "#{f.level == :error ? '✗ error' : '! warning'} #{f.message}" }
      errors = findings.count { |f| f.level == :error }
      @out.puts(errors.zero? ? "✓ pass control plane: #{plane.phases.size} phases, #{plane.skill_names.size} skills, no errors" : "✗ fail control plane: #{errors} error(s)")
      errors.zero? ? 0 : 2
    end

    def change
      sub = @argv.shift
      case sub
      when "new"
        slug = @argv.shift or raise ArgumentError, "Usage: soft-foundry change new <slug> [--title TITLE] [--branch BRANCH] [--track TRACK]"
        title = option("--title")
        branch = option("--branch") || (git.repository? ? git.branch : nil)
        track = option("--track") || plane.default_track
        unless plane.track(track)
          @err.puts "unknown track '#{track}'; .ai/workflow.yml defines: #{plane.track_names.join(', ')}"
          return EXIT_TARGET
        end
        record = ChangeRecord.create(@root, slug, control_plane: plane, title: title, branch: branch, worktree: @root, track: track)
        @out.puts "created #{relative(record.dir)} with #{plane.phases.size} phase directories"
        @out.puts "branch: #{branch || slug}"
        @out.puts track_line(record)
        billing_notice(record: record)
        0
      when "status"
        status(@argv.shift || current_slug)
      when "list"
        list_changes.each { |slug| @out.puts slug }
        0
      when "close"
        change_close(@argv.shift)
      when "request-discharge"
        change_request_discharge(@argv.shift)
      when "vet"
        change_vet(@argv.shift)
      when "reopen"
        change_reopen(@argv.shift)
      else
        @err.puts "Usage: soft-foundry change <new|status|list|vet|reopen|close|request-discharge>"
        1
      end
    end

    # The person's acceptance of an explored feature. Everything refused
    # here is something the person is told how to fix; the record itself
    # only changes once all of it holds.
    def change_vet(slug)
      slug or raise ArgumentError, "Usage: soft-foundry change vet <slug> [--by NAME]"
      by = option("--by") || (git.repository? && git.user_name) || ENV["USER"] || "unknown"
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?

      record = load_record(slug)
      definition = record.track_definition
      unless definition&.exploring?
        @err.puts "#{slug}: track '#{record.track}' has no exploring stage, so there is nothing to vet; the phases apply in order"
        return EXIT_TARGET
      end
      unless record.exploring?
        @err.puts "#{slug}: is not exploring (status: #{record.metadata['status']}); `change reopen` sends a vetted change back to exploring"
        return EXIT_TARGET
      end

      problems = []
      risk = record.metadata["risk"].to_s
      if risk.empty? || risk.match?(Gate::PLACEHOLDER)
        problems << "risk is not classified in metadata.yml; classify it first (a high risk change must move to the gated track)"
      elsif (forced = plane.track_forced_by_risk(risk)) && forced != record.track
        problems << "risk #{risk} forces the #{forced} track; set track: #{forced} and status: intake in metadata.yml and run the phases in order"
      end
      problems << "#{relative(record.iterations_path)} records no iteration; the exploring stage has to have happened before it can be vetted" if record.iterations.empty?
      gate = Gate.new(record, git: git)
      definition.vet_requires.each do |id|
        phase = plane.phase(id) or next problems << "track #{record.track} requires unknown phase '#{id}'"
        phase_status = record.phase_status(phase)
        if phase_status != "complete"
          problems << "#{phase.output} is #{phase_status || 'missing'}; it must be complete with no TBD before vetting"
          next
        end
        result = gate.evaluate(phase)
        problems << "#{phase.output} gate fails: #{result.checks.select { |c| c.outcome == :fail }.map { |c| "#{c.name} (#{c.detail})" }.join('; ')}" if result.failed?
        if git.repository?
          dirty = git.dirty_paths.select { |p| p.start_with?("changes/#{slug}/#{phase.output}/") }
          problems << "#{phase.output} has uncommitted changes (#{dirty.first(3).join(', ')}); commit it so the vet can lock it at a commit" unless dirty.empty?
        end
      end
      unless problems.empty?
        @err.puts "#{slug}: cannot vet"
        problems.each { |p| @err.puts "  ✗ fail #{p}" }
        return EXIT_TARGET
      end

      sha = git.repository? ? git.head_sha : nil
      record.vet!(by: by, commit: sha)
      @out.puts "#{slug}: vetted by #{by} at #{sha ? sha[0, 12] : 'no commit (not a git repository)'}"
      @out.puts "  02-specification is locked at that commit; phases from 05-implementation onward now apply as on the gated track"
      print_advisories(record)
      0
    end

    # Back to exploring: the person wants the feature reshaped, not fixed.
    def change_reopen(slug)
      slug or raise ArgumentError, "Usage: soft-foundry change reopen <slug> --reason TEXT"
      reason = option("--reason")
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?
      raise ArgumentError, "--reason is required: say why the feature is going back to exploring" if reason.to_s.strip.empty?

      record = load_record(slug)
      unless record.track_definition&.exploring?
        @err.puts "#{slug}: track '#{record.track}' has no exploring stage to reopen into"
        return EXIT_TARGET
      end
      if record.exploring?
        @out.puts "#{slug}: already exploring"
        return 0
      end
      if record.metadata["status"].to_s == "closed"
        @err.puts "#{slug}: is closed; a merged change is reshaped by a new change, not by reopening this record"
        return EXIT_TARGET
      end
      reset = record.reopen!(reason: reason)
      @out.puts "#{slug}: reopened for exploring (#{reason})"
      @out.puts(reset.empty? ? "  no hardening phase had started" : "  reset to pending, outputs kept: #{reset.join(', ')}")
      0
    end

    def track_line(record)
      definition = record.track_definition
      return "track: #{record.track} (not defined in .ai/workflow.yml)" unless definition
      line = "track: #{record.track}"
      if record.exploring?
        n = record.iterations.size
        last = record.iterations.last
        deployed = last && last["deployed"].is_a?(Hash) && last["deployed"]["environment"]
        line += " (exploring; #{n} #{n == 1 ? 'iteration' : 'iterations'} recorded#{deployed ? ", last deployed to #{deployed}" : ''}; run `soft-foundry change vet` when the person has accepted the feature)"
      elsif (v = record.vetted)
        line += " (vetted by #{v['by']} at #{v['commit'].to_s[0, 12]} on #{v['at']}; specification locked)"
      elsif definition.exploring?
        line += " (exploring stage not entered)"
      end
      line
    end

    # The mechanical half (branch merged, no undischarged condition left
    # unconfirmed) of closing a change record's lifecycle. See
    # .ai/skills/final-judgment/template/evidence.yml for `undischarged`.
    def change_close(slug)
      slug or raise ArgumentError, "Usage: soft-foundry change close <slug> [--pr NUMBER] [--confirm ID]... [--force]"
      pr = option("--pr")
      confirmed = options("--confirm")
      force = flag("--force")
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?

      record = load_record(slug)
      if record.metadata["status"] == "closed"
        @out.puts "#{slug}: already closed"
        return 0
      end

      unless force
        branch = git.repository? ? git.default_branch : nil
        sha = record.finished_commit_sha
        if sha.nil?
          @err.puts "#{slug}: has not reached the end of its lifecycle yet (a required phase is still pending and not skipped-with-rationale), so there is nothing to confirm as merged; pass --force to close anyway"
          return EXIT_TARGET
        end
        unless branch && git.ancestor?(sha, branch)
          @err.puts "#{slug}: finished commit #{sha} is not reachable from #{branch || 'the default branch'} yet; pass --force to close anyway"
          return EXIT_TARGET
        end
      end

      undischarged = record.undischarged_acceptance
      confirmed += (@pr_discharge || PrDischarge.new(@root)).confirmed_ids(pr) if pr
      missing = undischarged.reject { |item| confirmed.include?(item["id"]) }
      unless missing.empty?
        @err.puts "#{slug}: cannot close - undischarged and unconfirmed: #{missing.map { |m| m['id'] }.join(', ')}"
        @err.puts "confirm with --confirm ID (repeatable) once a human has verified it, or --pr NUMBER if a human already replied \"CONFIRMED: <id>\" there"
        return EXIT_TARGET
      end

      unless undischarged.empty?
        record.discharge!(undischarged, confirmed_by: pr ? "PR ##{pr} comment" : "explicit --confirm")
      end
      # Closing is the go-live moment, so anything still owed is said here
      # one last time; it is advice for the person shipping, not a refusal.
      print_advisories(record)
      record.close!
      @out.puts "#{slug}: closed#{undischarged.empty? ? '' : " (discharged: #{undischarged.map { |i| i['id'] }.join(', ')})"}"
      0
    end

    def change_request_discharge(slug)
      slug or raise ArgumentError, "Usage: soft-foundry change request-discharge <slug> --pr NUMBER"
      pr = option("--pr") or raise ArgumentError, "--pr is required"
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?

      record = load_record(slug)
      items = record.undischarged_acceptance
      if items.empty?
        @out.puts "#{slug}: nothing undischarged"
        return 0
      end
      (@pr_discharge || PrDischarge.new(@root)).request(pr, items)
      @out.puts "#{slug}: posted a discharge request to PR ##{pr} for #{items.map { |i| i['id'] }.join(', ')}"
      0
    end

    def status(slug)
      record = load_record(slug)
      meta = record.metadata
      @out.puts "#{slug}: #{meta.dig('change', 'title')}  [status: #{meta['status']}, phase: #{meta['current_phase']}, risk: #{meta['risk']}]"
      @out.puts "  #{track_line(record)}"
      results = Gate.new(record, git: git).evaluate_all
      results.each { |r| @out.puts format("  %-22s %-12s %s", r.phase.output, r.status, summarize(r)) }
      print_advisories(record)
      results.any?(&:failed?) ? 2 : 0
    end

    def budget
      sub = @argv.shift
      case sub
      when "status" then budget_status
      when "record" then budget_record
      when "threshold" then budget_threshold
      else
        @err.puts "Usage: soft-foundry budget <status|record|threshold> [options]"
        1
      end
    end

    def budget_status
      slug = option("--change") || current_slug
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?
      record = load_record(slug)
      b = Budget.new(record)
      risk = declared_risk(record)
      policy = Budget.policy(plane, risk: risk)
      mode = Billing.detect
      t = b.totals
      @out.puts "change: #{slug}  risk: #{risk || 'unset'}"
      @out.puts "billing: #{mode.mode} (#{mode.reason})"
      @out.puts "tokens in/out: #{t.tokens_in}/#{t.tokens_out}"
      if t.estimated_usd
        @out.puts format("estimated spend: $%.2f", t.estimated_usd)
      else
        @out.puts "estimated spend: unknown (no priced entries recorded)"
      end
      @out.puts "entries missing cost: #{t.entries_missing_cost}" if t.entries_missing_cost.positive?
      if mode.subscription?
        @out.puts "budget: not applicable on a subscription; the ledger above is kept for reference only (set #{Billing::OVERRIDE_ENV}=api if usage here is actually metered)"
        return 0
      end
      @out.puts format("cap (max_usd_per_change): $%.2f", policy.max_usd_per_change) if policy.max_usd_per_change
      @out.puts format("requires human approval above: $%.2f (see .ai/policies/human-boundaries.yml)", policy.require_human_approval_above_usd) if policy.require_human_approval_above_usd
      @out.puts threshold_line(Budget.warn_threshold(@root, policy), t.estimated_usd)
      if b.over_cap?(policy)
        @out.puts "OVER CAP: this change's declared budget is a financial commitment under human-boundaries.yml; stop and get approval before continuing."
        return 2
      end
      0
    end

    def budget_record
      slug = option("--change") || current_slug
      phase = option("--phase") or raise ArgumentError, "Usage: soft-foundry budget record --phase PHASE --provider NAME --model NAME --tokens-in N --tokens-out N [--usd X] [--change SLUG]"
      provider = option("--provider") or raise ArgumentError, "--provider is required"
      model = option("--model") or raise ArgumentError, "--model is required"
      tokens_in = Integer(option("--tokens-in") || raise(ArgumentError, "--tokens-in is required"))
      tokens_out = Integer(option("--tokens-out") || raise(ArgumentError, "--tokens-out is required"))
      usd = option("--usd")
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?
      record = load_record(slug)
      b = Budget.new(record)
      before = b.totals.estimated_usd
      b.record!(phase:, provider:, model:, tokens_in:, tokens_out:, estimated_usd: usd&.to_f)
      @out.puts "recorded: #{phase} #{provider}/#{model} #{tokens_in}in/#{tokens_out}out#{usd ? format(' $%.2f', usd.to_f) : ''}"

      # The ledger is the only thing that moves, so this is the one moment a
      # periodic warning can fire: when this entry pushed the running total
      # past another interval, the approval line, or the cap.
      mode = Billing.detect
      return 0 if mode.subscription?
      after = b.totals.estimated_usd
      policy = Budget.policy(plane, risk: declared_risk(record))
      threshold = Budget.warn_threshold(@root, policy)
      crossed = threshold.enabled? ? Budget.thresholds_crossed(before, after, threshold.usd) : []
      unless crossed.empty?
        cap = policy.max_usd_per_change ? format(" of the $%.2f cap", policy.max_usd_per_change) : ""
        @out.puts format("WARNING: recorded spend for %s has passed $%.2f (now $%.2f%s); `soft-foundry budget threshold <usd|off>` adjusts how often this warns", slug, crossed.last, after, cap)
      end
      approval = policy.require_human_approval_above_usd
      if approval && after && after > approval && (before.nil? || before <= approval)
        @out.puts format("HUMAN APPROVAL REQUIRED: recorded spend $%.2f is above $%.2f; continuing is a financial commitment under .ai/policies/human-boundaries.yml", after, approval)
      end
      if b.over_cap?(policy)
        @out.puts "OVER CAP: this change's declared budget is a financial commitment under human-boundaries.yml; stop and get approval before continuing."
        return 2
      end
      0
    end

    # Show or set the machine-local warning interval. `off` silences the
    # periodic warning, `default` drops the local override so the policy's
    # value applies again.
    def budget_threshold
      value = @argv.shift
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?
      policy = Budget.policy(plane)
      unless value.nil?
        case value
        when "off" then Budget.set_warn_threshold!(@root, 0)
        when "default" then Budget.set_warn_threshold!(@root, nil)
        else
          usd = begin
            Float(value)
          rescue ArgumentError, TypeError
            raise TargetError, "expected a dollar amount, `off`, or `default`; got '#{value}'"
          end
          raise TargetError, "the warning interval must be positive; use `off` to silence warnings" unless usd.positive?
          Budget.set_warn_threshold!(@root, usd)
        end
      end
      threshold = Budget.warn_threshold(@root, policy)
      @out.puts threshold_line(threshold, nil)
      @out.puts "source: #{threshold.source}#{threshold.source == Budget::LOCAL_SETTINGS ? ' (machine-local, gitignored)' : ''}"
      0
    end

    def threshold_line(threshold, spent)
      return "periodic warnings: off (`soft-foundry budget threshold <usd>` turns them on)" unless threshold.enabled?
      nxt = Budget.next_threshold(spent, threshold.usd)
      format("warns every $%.2f of recorded spend (next warning at $%.2f)", threshold.usd, nxt)
    end

    def declared_risk(record)
      risk = record.metadata["risk"]
      risk.nil? || risk == "TBD" ? nil : risk
    end

    # How model usage is paid for here and, only when it is metered, that
    # the budget policy applies and where the current change stands. Printed
    # wherever spend is about to start or a change begins. A subscription is
    # a flat fee with nothing metered, so nothing budget-shaped applies.
    def billing_notice(shell: nil, record: nil, root: @root)
      mode = Billing.detect(shell: shell)
      plane = root == @root ? self.plane : ControlPlane.new(root)
      if mode.subscription?
        @out.puts "billing: subscription (#{mode.reason}); no budget applies"
        @out.puts "         set #{Billing::OVERRIDE_ENV}=api if usage here is actually metered"
        return mode
      end
      @out.puts "billing: API key (#{mode.reason}); the budget policy in .ai/policies/budget.yml applies"
      return mode unless plane.present?
      record ||= begin
        load_record(current_slug)
      rescue StandardError
        nil
      end
      risk = record && declared_risk(record)
      policy = Budget.policy(plane, risk: risk)
      threshold = Budget.warn_threshold(root, policy)
      cap = policy.max_usd_per_change ? format("cap $%.2f per change (risk: %s)", policy.max_usd_per_change, risk || "unset") : "no per-change cap"
      approval = policy.require_human_approval_above_usd ? format("; human approval required above $%.2f", policy.require_human_approval_above_usd) : ""
      @out.puts "budget:  #{cap}#{approval}"
      spent = record && Budget.new(record).totals.estimated_usd
      @out.puts "budget:  #{threshold_line(threshold, spent)}"
      if record
        @out.puts format("budget:  %s recorded so far: $%.2f", record.slug, spent || 0.0)
      else
        @out.puts "budget:  no change record for this branch yet; spend is tracked per change with `soft-foundry budget record`"
      end
      mode
    rescue Error
      raise
    rescue StandardError => e
      @out.puts "budget:  could not read the budget policy (#{e.message})"
      mode
    end

    def gate
      target = @argv.shift or raise ArgumentError, "Usage: soft-foundry gate <phase|all> [--change SLUG]"
      slug = option("--change") || current_slug
      record = load_record(slug)
      gate = Gate.new(record, git: git)
      results = target == "all" ? gate.evaluate_all : [gate.evaluate(target)]
      results.each { |r| print_result(r) }
      print_advisories(record)
      results.any?(&:failed?) ? 2 : 0
    end

    def ci
      code = check
      default_branch = git.repository? ? git.default_branch : nil
      list_changes.each do |slug|
        record = load_record(slug)
        if record.metadata["status"] == "closed"
          @out.puts "\nchange #{slug} (closed, skipped)"
          next
        end
        @out.puts "\nchange #{slug}"
        results = Gate.new(record, git: git).evaluate_all
        results.reject(&:skipped?).each { |r| print_result(r) }
        code = 2 if results.any?(&:failed?)
        print_advisories(record)
        sha = record.finished_commit_sha
        if default_branch && sha && git.ancestor?(sha, default_branch)
          @out.puts "  ✗ fail merged into #{default_branch} but status is '#{record.metadata['status']}', not 'closed' — run `soft-foundry change close #{slug}`"
          code = 2
        end
      end
      @out.puts(code.zero? ? "\n✓ ci passed" : "\n✗ ci failed")
      code
    end

    def hooks
      sub = @argv.shift
      claude = flag("--claude")
      local = flag("--local")
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?
      case sub
      when "install"
        if claude
          path = Hooks.install_claude(@root, local: local)
          mode, source = Guard.mode(@root)
          @out.puts "installed guard hook in #{relative(path)} (PreToolUse: #{Hooks::GUARD_MATCHER})"
          @out.puts "guard mode: #{mode} (#{source})"
        else
          @out.puts "installed #{relative(Hooks.install(@root))}"
        end
        0
      when "uninstall"
        raise ArgumentError, "Usage: soft-foundry hooks uninstall --claude [--local]" unless claude
        path = Hooks.uninstall_claude(@root, local: local)
        @out.puts(path ? "removed guard hook from #{relative(path)}" : "no guard hook installed in #{relative(Hooks.claude_settings_path(@root, local: local))}")
        0
      else
        raise ArgumentError, "Usage: soft-foundry hooks install [--claude [--local]] | hooks uninstall --claude [--local]"
      end
    end

    # `learn list` shows instincts across every record; `learn promote`
    # copies those above the threshold into .ai/rules/learned.md through
    # the change record on the current branch.
    def learn
      sub = @argv.shift
      min = option("--min-confidence")
      dry_run = flag("--dry-run")
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?
      threshold = min ? Float(min) : Learning.min_confidence(@root)
      case sub
      when "list"
        instincts = Learning.all(@root, plane).select { |i| i.confidence >= (min ? threshold : 0.0) }
        if instincts.empty?
          @out.puts "no instincts recorded#{min ? " at or above #{format('%.2f', threshold)}" : ''}; the learning phase writes them to 15-learning/instincts.yml"
        else
          instincts.each { |i| @out.puts format("%.2f %s %s (%s; %s)", i.confidence, i.change, i.id, i.trigger, i.action) }
        end
        0
      when "promote"
        slug = begin
          current_slug
        rescue RuntimeError => e
          @err.puts "✗ fail learn promote: #{e.message}; a promotion is a change to .ai/rules and goes through a change record"
          return EXIT_TARGET
        end
        record = load_record(slug)
        if record.metadata["status"].to_s == "closed"
          @err.puts "✗ fail learn promote: change #{slug} is closed; open a new change for the promotion"
          return EXIT_TARGET
        end
        already = Learning.promoted_ids(@root)
        chosen = []
        Learning.all(@root, plane).each do |i|
          if already.include?(i.id) || chosen.any? { |c| c.id == i.id }
            @out.puts "- skip #{i.id}: already in #{Learning::RULES}"
          elsif i.confidence < threshold
            @out.puts "- skip #{i.id}: confidence #{format('%.2f', i.confidence)} is below #{format('%.2f', threshold)}"
          elsif dry_run
            @out.puts "would promote #{i.id} (#{format('%.2f', i.confidence)}, from #{i.change})"
          else
            chosen << i
            @out.puts "✓ pass promoted #{i.id} (#{format('%.2f', i.confidence)}, from #{i.change})"
          end
        end
        unless chosen.empty? || dry_run
          Learning.promote!(@root, chosen)
          @out.puts "wrote #{Learning::RULES} through change #{slug}; commit it with this change's record"
        end
        0
      else
        raise ArgumentError, "Usage: soft-foundry learn <list|promote> [--min-confidence X] [--dry-run]"
      end
    end

    # `phase run <phase>`: one lifecycle phase in a fresh coding-shell
    # session, stamped with how it ran, gated when it returns.
    def phase
      sub = @argv.shift
      raise ArgumentError, "Usage: soft-foundry phase run <phase> [--change SLUG] [--shell claude|codex] [--dry-run] [-- shell args...]" unless sub == "run"
      target = @argv.shift or raise ArgumentError, "Usage: soft-foundry phase run <phase> [--change SLUG] [--shell claude|codex] [--dry-run] [-- shell args...]"
      slug = option("--change") || current_slug
      shell_name = option("--shell") || "claude"
      dry_run = flag("--dry-run")
      extra = []
      if (i = @argv.index("--"))
        extra = @argv[(i + 1)..]
        @argv = @argv[0...i]
      end
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?

      record = load_record(slug)
      phase = plane.phase(target) or raise TargetError, "unknown phase '#{target}'; lifecycle phases: #{plane.phases.map(&:id).join(', ')}"
      runner = PhaseRunner.new(@root, plane: plane, git: git, record: record)
      if (why = runner.refusal(phase))
        @err.puts "#{slug}: cannot run #{phase.id}: #{why}"
        return EXIT_TARGET
      end
      launch = runner.launch(phase, shell: shell_name, extra: extra)

      if shell_name == "claude" && Hooks.claude_installed?(@root).nil?
        @err.puts "! warn guard: the guard hook is not installed here, so the session's tool calls will not be checked against the #{plane.skill(phase.skill).name} skill's permissions (`soft-foundry hooks install --claude`)"
      end
      if dry_run
        @out.puts "would run #{phase.id} of #{slug} with: #{launch.executable} #{launch.args.map { |a| a == launch.prompt ? '<prompt>' : Shellwords.escape(a) }.join(' ')}"
        @out.puts "--- prompt ---"
        @out.puts launch.prompt
        return 0
      end

      billing_notice(shell: shell_name)
      runner.begin!(phase, launch)
      @out.puts "running #{phase.id} of #{slug} in a fresh #{shell_name} session (#{plane.skill(phase.skill).name} skill); executed_by recorded in #{relative(record.handoff_path(phase))}"
      @out.flush
      @err.flush
      status = (@runner || method(:spawn_shell)).call(launch)
      runner.finish!(phase, status)
      @out.puts "#{shell_name} exited #{status}"
      result = Gate.new(record, git: git).evaluate(phase)
      print_result(result)
      print_advisories(record)
      return EXIT_TARGET unless status.zero?
      result.failed? ? 2 : 0
    end

    # Runs the coding shell as a child with inherited stdio, in the
    # repository root, and returns its exit status.
    def spawn_shell(launch)
      executable = Shell.resolve(launch.executable)
      pid = Process.spawn(executable, *launch.args, chdir: @root)
      Process.wait(pid)
      $?.exitstatus || 1
    end

    # The PreToolUse guard. Reads the hook payload from stdin, decides, and
    # answers the way Claude Code expects: exit 2 with the reason on stderr
    # to refuse, exit 0 to allow. In warn mode a violation is reported on
    # stderr and allowed. Every violation is appended to the guard log.
    def guard
      mode, = Guard.mode(@root)
      return 0 if mode == "off"
      payload = begin
        JSON.parse(@input.read.to_s)
      rescue JSON::ParserError
        nil
      end
      unless payload.is_a?(Hash) && payload["tool_name"]
        @err.puts "#{mode == 'block' ? '✗ fail' : '! warn'} guard: could not read the tool call from stdin#{mode == 'block' ? '; refusing it' : ''}"
        return mode == "block" ? 2 : 0
      end
      tool = payload["tool_name"].to_s
      input = payload["tool_input"].is_a?(Hash) ? payload["tool_input"] : {}
      guard = Guard.new(@root, plane: plane, git: git)
      decision = guard.decide(tool, input)
      return 0 unless decision.violation?
      guard.log(decision, mode: mode, tool_name: tool)
      where = decision.paths.empty? ? tool : "#{tool} #{decision.paths.join(', ')}"
      if mode == "block"
        @err.puts "✗ fail guard: #{where} #{decision.reason}; the #{decision.skill} skill's permissions.yml does not allow it (mode: block, .ai/policies/enforcement.yml)"
        2
      else
        @err.puts "! warn guard: #{where} #{decision.reason}; the #{decision.skill} skill's permissions.yml does not allow it (mode: warn, logged to #{Guard::LOG})"
        0
      end
    end

    def update
      yes = flag("--yes")
      raise TargetError, "unknown option(s): #{@argv.join(' ')}" unless @argv.empty?

      result = (@updater || Updater.new).check
      if result.error
        @out.puts "update: could not check for a new version (#{result.error})"
        return EXIT_TARGET
      end

      @out.puts "current: #{result.current}"
      @out.puts "latest:  #{result.latest}"
      unless result.update_available
        @out.puts "up to date"
        return 0
      end

      unless yes
        @out.puts "a newer version is available; rerun `soft-foundry update --yes` to install it"
        return 0
      end

      @out.puts "installing #{result.latest}..."
      install = (@updater || Updater.new).install!(result.latest)
      @out.puts install.message
      unless install.ok
        @out.puts "update: install failed"
        return EXIT_TARGET
      end
      @out.puts "updated to #{result.latest}"
      0
    end

    def print_result(result)
      @out.puts "#{result.phase.output}  #{result.status}  #{result.failed? ? 'FAIL' : (result.skipped? ? 'SKIP' : 'PASS')}"
      result.checks.each do |c|
        mark = { pass: "✓ pass", fail: "✗ fail", warn: "! warn", skip: "- skip" }.fetch(c.outcome)
        @out.puts "  #{mark} #{c.name}#{c.detail.to_s.empty? ? '' : ": #{c.detail}"}"
      end
    end

    # Go-live advisories: what a person should address before this change
    # ships. Printed with a status word per line and never affects the exit
    # code; see .ai/rules/accessibility.md and Advisory.
    def print_advisories(record)
      notices = Advisory.new(record).notices
      return if notices.empty?
      word = notices.size == 1 ? "issue" : "issues"
      @out.puts "advisory: #{notices.size} #{word} to address before #{record.slug} goes live (informational, does not block the gate)"
      notices.each { |n| @out.puts "  ! warn #{n.area}: #{n.message}" }
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
              --maturity scan|deep|off (default scan)  --reassess
          soft-foundry onboard [options]           discover providers, repair agent adapters, assess maturity
              --maturity scan|deep|off (default scan)  --reassess
          soft-foundry doctor                     validate repository bootstrap
          soft-foundry check                      lint the .ai/ control plane
          soft-foundry change new <slug> [--track gated|iterative]
                                                  create changes/<slug>/ from phase templates; the track
                                                  defaults to .ai/workflow.yml tracks.default
          soft-foundry change status [slug]       show track, phase status, and gate results
          soft-foundry change list                list change records
          soft-foundry change vet <slug> [--by NAME]
                                                  iterative track: record the person's acceptance of the
                                                  explored feature, lock the specification at HEAD, and
                                                  make the phases from implementation onward apply
          soft-foundry change reopen <slug> --reason TEXT
                                                  iterative track: send a vetted change back to exploring,
                                                  resetting every phase from implementation onward
          soft-foundry change close <slug> [--pr N] [--confirm ID]... [--force]
                                                  mark a merged change's lifecycle closed; refuses if
                                                  unmerged, or if an undischarged item lacks a --confirm ID
                                                  or a PR comment reading "CONFIRMED: <id>"
          soft-foundry change request-discharge <slug> --pr N
                                                  post a PR comment asking a human to confirm each
                                                  undischarged acceptance criterion
          soft-foundry gate <phase|all> [--change SLUG]
                                                  evaluate a phase's completion gate
          soft-foundry learn list [--min-confidence X]
                                                  instincts recorded by every change's learning phase,
                                                  highest confidence first
          soft-foundry learn promote [--min-confidence X] [--dry-run]
                                                  copy instincts at or above the threshold (.ai/policies/learning.yml,
                                                  default 0.80) into .ai/rules/learned.md through the change
                                                  record on the current branch
          soft-foundry phase run <phase> [--change SLUG] [--shell claude|codex] [--dry-run] [-- args...]
                                                  run one phase in a fresh coding-shell session with only its
                                                  skill in the prompt; stamps executed_by in the handoff and
                                                  gates the phase when the session returns
          soft-foundry budget status [--change SLUG]
                                                  show billing mode and compare recorded spend against
                                                  .ai/policies/budget.yml (no budget on a subscription)
          soft-foundry budget record --phase P --provider NAME --model NAME
                                     --tokens-in N --tokens-out N [--usd X] [--change SLUG]
                                                  record a phase's spend into the change's ledger; warns
                                                  each time the total passes another warning interval
          soft-foundry budget threshold [USD|off|default]
                                                  show or set how often recorded spend warns (machine-local)
          soft-foundry ci                         check + gate every change record (used by CI and pre-commit)
          soft-foundry hooks install              install the pre-commit hook
          soft-foundry hooks install --claude [--local]
                                                  install the PreToolUse guard into .claude/settings.json
                                                  (or settings.local.json) so a coding shell's tool calls
                                                  are checked against the active skill's permissions.yml
          soft-foundry hooks uninstall --claude [--local]
                                                  remove only Soft Foundry's guard entry
          soft-foundry guard                      the hook itself: reads a tool call from stdin, exits 2 to
                                                  refuse it in block mode; mode from .ai/policies/enforcement.yml,
                                                  .soft-foundry/enforcement.yml, or SOFT_FOUNDRY_GUARD=warn|block|off
          soft-foundry update [--yes]             check RubyGems for a newer release; --yes installs it
          soft-foundry models                     show locally accessible models
          soft-foundry shell claude|codex|grok    launch a coding shell in this repository
          soft-foundry version

        `AGENTS.md` and `.ai/` are canonical. Vendor files such as `CLAUDE.md` only point to them.
      TEXT
    end
  end
end
