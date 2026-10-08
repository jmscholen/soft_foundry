# frozen_string_literal: true

require "time"
require "yaml"
require "shellwords"
require "securerandom"
require_relative "control_plane"
require_relative "change_record"
require_relative "gate"
require_relative "hooks"
require_relative "shell"
require_relative "phase_provider"

module SoftFoundry
  # Runs one lifecycle phase of a change in a fresh coding-shell session:
  # a new process with only the phase's skill contract in its prompt, the
  # runtime guard active if installed, and the handoff stamped with how it
  # ran. Separation of duties then rests on a process boundary rather
  # than on a note in the handoff saying the implementing session also
  # reviewed its own work.
  class PhaseRunner
    Launch = Data.define(:shell, :executable, :args, :prompt, :session_id)

    # Non-interactive invocations. Each takes the prompt as its last
    # argument; anything after `--` on the command line is appended first.
    # Claude Code and Grok accept the session ID up front, so the record
    # can say which session to resume; Codex picks its own, and the runner
    # takes it from the session ledger afterwards.
    SHELLS = {
      "claude" => ->(prompt, extra, id, name) { ["-p", "--session-id", id, "--name", name, *extra, prompt] },
      "codex" => ->(prompt, extra, _id, _name) { ["exec", *extra, prompt] },
      # `grok -p` (--single) is its headless form and takes the prompt as its
      # value, so it comes last with the prompt right after it.
      "grok" => ->(prompt, extra, id, _name) { ["-s", id, *extra, "-p", prompt] }
    }.freeze
    PRESET_ID = %w[claude grok].freeze

    # Shells with a PreToolUse hook the guard can run in. Claude Code and
    # Codex have their own install; Grok runs the Claude Code entry from
    # .claude/settings.json in a folder it trusts.
    HOOKED_SHELLS = %w[claude codex grok].freeze

    # The provider a phase ran on (see PhaseProvider).
    def self.provider_of(handoff) = PhaseProvider.of(handoff)

    Choice = Data.define(:shell, :line)

    # The shell for a phase when the person named none. A skill that
    # declares prefer_different_provider_from gets the first installed
    # shell, in SHELLS order, on a provider none of those phases used;
    # every other phase gets claude, as before. `line` explains the
    # choice (a `shell:` line, or a `! warn shell:` line), or is nil.
    def default_shell(phase, installed: ->(s) { Shell.resolve(s) rescue nil })
      skill = @plane.skill(phase.skill)
      named = Array(skill.definition["prefer_different_provider_from"]).filter_map { |id| @plane.phase(id.to_s) }
      return Choice.new(shell: "claude", line: nil) if named.empty?
      used = named.filter_map do |p|
        next unless @record.phase_status(p) == "complete"
        provider = self.class.provider_of(@record.handoff(p))
        [p, provider]
      end
      unknown = used.select { |_, provider| provider.nil? }.map { |p, _| words(p) }
      known = used.reject { |_, provider| provider.nil? }
      on_path = SHELLS.keys.select { |s| installed.call(s) }
      fallback = on_path.first || "claude"
      unless unknown.empty?
        return Choice.new(shell: fallback, line: "! warn shell: the provider of #{unknown.join(' and ')} is not recorded, so #{phase.id} runs on #{fallback}; name one with --shell")
      end
      return Choice.new(shell: fallback, line: nil) if known.empty?
      providers = known.map(&:last).uniq
      ran = known.map { |p, provider| "#{words(p)} #{known.index([p, provider]).zero? ? 'ran on' : 'on'} #{provider}" }.join(", ")
      pick = on_path.find { |s| !providers.include?(PhaseProvider.of_shell(s)) }
      if pick
        Choice.new(shell: pick, line: "shell: #{pick} (#{ran}; the #{skill.name} skill prefers a different provider)")
      else
        Choice.new(shell: fallback, line: "! warn shell: no installed shell runs on a provider other than #{providers.join(' or ')}, so #{phase.id} runs on #{fallback}")
      end
    end

    def initialize(root, plane:, git:, record:)
      @root = File.expand_path(root)
      @plane = plane
      @git = git
      @record = record
    end

    # Why the phase cannot be run now, or nil. Everything here is also
    # what the gate would say afterwards; checking first saves a session.
    def refusal(phase)
      return "change #{@record.slug} is exploring; the exploring stage is worked with the person, not by a runner (run `change vet` first)" if @record.exploring?
      status = @record.metadata["status"].to_s
      return "change #{@record.slug} is #{status}" if %w[closed judged].include?(status)
      return "#{phase.output} is already complete; rerun it only after the work it rests on has changed (the gate will say when it is stale)" if @record.phase_status(phase) == "complete"
      prev = @plane.effective_predecessor(phase, skip: ->(p) { @record.skippable?(p) }) { |p| @record.phase_status(p) }
      if prev && @record.phase_status(prev) != "complete"
        return "#{phase.output} cannot start: its predecessor #{prev.output} is #{@record.phase_status(prev) || 'missing'}"
      end
      nil
    end

    # The instructions the fresh session receives. Deliberately short: it
    # points at the canonical files rather than restating them, and names
    # exactly what may be written.
    def prompt(phase)
      skill = @plane.skill(phase.skill)
      files = ControlPlane::SKILL_FILES.map { |f| ".ai/skills/#{skill.name}/#{f}" }
      <<~PROMPT.strip
        You are a fresh-context agent running one lifecycle phase of a Soft Foundry change, and nothing else.

        Change: #{@record.slug} (branch #{@record.metadata.dig('git', 'branch')})
        Phase: #{phase.id} (changes/#{@record.slug}/#{phase.output}/)
        Skill: #{skill.name} (profile #{skill.profile})

        1. Read AGENTS.md and .ai/README.md. Then load only this phase's skill contract: #{files.join(', ')}.
        2. Do the phase's work as the skill describes, reading the earlier phases under changes/#{@record.slug}/ that the skill's permissions.yml allows. Write only where that file allows; the runtime guard enforces it where installed and it is policy everywhere else.
        3. When the work is done, fill changes/#{@record.slug}/#{phase.output}/handoff.yml: status complete, commit_sha (the HEAD the outputs describe), completed_at, resolved_model (provider and model actually used), outputs, findings for later phases, and next. Do not edit executed_by; the runner writes it.
        4. Do not alter any other phase's evidence or handoff, do not weaken requirements to obtain a pass, and do not run `soft-foundry phase run` yourself. If the work cannot be completed, set status blocked with the reason under blocking rather than pretending.
        5. Stop when the handoff is written. `soft-foundry gate #{phase.id}` will be run on your output afterwards.
      PROMPT
    end

    def launch(phase, shell:, extra: [])
      builder = SHELLS.fetch(shell) { raise ArgumentError, "unknown shell '#{shell}'; phase run supports #{SHELLS.keys.join(', ')}" }
      id = PRESET_ID.include?(shell) ? SecureRandom.uuid : nil
      text = prompt(phase)
      Launch.new(shell: shell, executable: shell, args: builder.call(text, extra, id, "#{@record.slug}/#{phase.id}"), prompt: text, session_id: id)
    end

    # Records how the phase is being run before the session starts, so a
    # session that dies still leaves the attempt in the record. Also moves
    # current_phase to this phase so the guard applies the right skill.
    def begin!(phase, launch, now: Time.now)
      path = File.join(@record.dir, "metadata.yml")
      meta = @record.metadata
      previous = meta["current_phase"]
      unless previous == phase.id
        meta["current_phase"] = phase.id
        File.write(path, YAML.dump(meta))
      end
      stamp_handoff(phase) do |h|
        h["status"] = "in_progress" if h["status"].to_s == "pending"
        h["started_at"] ||= now.utc.iso8601
        h["executed_by"] = { "runner" => "soft-foundry phase run", "shell" => launch.shell, "fresh_context" => true,
                             "started_at" => now.utc.iso8601, "finished_at" => nil, "exit_status" => nil, "previous_phase" => previous,
                             "session_id" => launch.session_id, "cwd" => @root }
      end
    end

    # `session_id`, when given, is one learned only after the session ran
    # (Codex's, from the ledger); a preset one is already recorded.
    def finish!(phase, exit_status, now: Time.now, session_id: nil)
      stamp_handoff(phase) do |h|
        by = (h["executed_by"].is_a?(Hash) ? h["executed_by"] : {}).merge("finished_at" => now.utc.iso8601, "exit_status" => exit_status)
        by["session_id"] = session_id if session_id
        h["executed_by"] = by
      end
    end

    # The newest session of `shell` the prompt hook recorded in this
    # repository since `since`, or nil (hook not installed, or none fired).
    def recorded_session(ledger, shell:, since:)
      root = File.realpath(@root)
      ledger.search(agent: shell).find do |e|
        e["first_at"].to_s >= since.to_s && [e["repo"], e["cwd"]].compact.any? { |dir| real(dir) == root }
      end&.fetch("session_id", nil)
    end

    private

    # "implementation" for implement, "remediation" for remediate.
    def words(phase)
      { "implement" => "implementation", "remediate" => "remediation" }.fetch(phase.id, phase.id.tr("_", " "))
    end

    def real(dir)
      File.realpath(dir)
    rescue SystemCallError
      dir
    end

    def stamp_handoff(phase)
      path = @record.handoff_path(phase)
      h = @record.handoff(phase) || {}
      yield h
      File.write(path, YAML.dump(h))
    end
  end
end
