# frozen_string_literal: true

require "time"
require "yaml"
require "shellwords"
require_relative "control_plane"
require_relative "change_record"
require_relative "gate"
require_relative "hooks"

module SoftFoundry
  # Runs one lifecycle phase of a change in a fresh coding-shell session:
  # a new process with only the phase's skill contract in its prompt, the
  # runtime guard active if installed, and the handoff stamped with how it
  # ran. Separation of duties then rests on a process boundary rather
  # than on a note in the handoff saying the implementing session also
  # reviewed its own work.
  class PhaseRunner
    Launch = Data.define(:shell, :executable, :args, :prompt)

    # Non-interactive invocations. Each takes the prompt as its last
    # argument; anything after `--` on the command line is appended first.
    SHELLS = {
      "claude" => ->(prompt, extra) { ["-p", *extra, prompt] },
      "codex" => ->(prompt, extra) { ["exec", *extra, prompt] }
    }.freeze

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
      Launch.new(shell: shell, executable: shell, args: builder.call(prompt(phase), extra), prompt: prompt(phase))
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
                             "started_at" => now.utc.iso8601, "finished_at" => nil, "exit_status" => nil, "previous_phase" => previous }
      end
    end

    def finish!(phase, exit_status, now: Time.now)
      stamp_handoff(phase) do |h|
        h["executed_by"] = (h["executed_by"].is_a?(Hash) ? h["executed_by"] : {}).merge("finished_at" => now.utc.iso8601, "exit_status" => exit_status)
      end
    end

    private

    def stamp_handoff(phase)
      path = @record.handoff_path(phase)
      h = @record.handoff(phase) || {}
      yield h
      File.write(path, YAML.dump(h))
    end
  end
end
