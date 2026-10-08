# frozen_string_literal: true

require "json"
require "time"
require "yaml"
require "fileutils"
require_relative "control_plane"
require_relative "change_record"
require_relative "git"
require_relative "panel"

module SoftFoundry
  # Runtime enforcement of a skill's declared permissions: a PreToolUse
  # guard a coding shell calls before every file or shell tool. It resolves
  # the active change from the branch, the active skill from the change's
  # status and current phase, expands that skill's permissions.yml through
  # the path groups, and decides whether the tool call stays inside them.
  #
  # The decision is the same in every mode; the mode only decides what the
  # shell is told. `warn` reports and lets the call through, `block`
  # refuses it, `off` says nothing. Every non-allow decision is appended
  # to the machine-local guard log so a warn-mode run leaves a trail.
  class Guard
    Decision = Data.define(:outcome, :reason, :skill, :paths) do # outcome: :allow | :violation
      def violation? = outcome == :violation
    end

    MODES = %w[warn block off].freeze
    DEFAULT_MODE = "warn"
    POLICY = ".ai/policies/enforcement.yml"
    LOCAL = ".soft-foundry/enforcement.yml"
    LOG = ".soft-foundry/guard.log"
    ENV_VAR = "SOFT_FOUNDRY_GUARD"

    # Grok runs this hook from .claude/settings.json in a folder it trusts
    # but sends its own tool names: write and search_replace (file_path),
    # read_file (target_file), run_terminal_command (command).
    WRITE_TOOLS = %w[Edit Write MultiEdit NotebookEdit write search_replace].freeze
    PATCH_TOOLS = %w[apply_patch].freeze # Codex file edits; also reported under Edit/Write with the patch in `command`
    READ_TOOLS = %w[Read read_file].freeze
    SHELL_TOOLS = %w[Bash run_terminal_command].freeze
    PATCH_HEADER = /\A\*\*\* (?:Add File|Update File|Delete File|Move to): (.+?)\s*\z/.freeze

    # The mode in effect: the environment, then the machine-local override,
    # then repository policy, then the default. Returns [mode, source].
    def self.mode(root, env: ENV)
      value = env[ENV_VAR].to_s.strip.downcase
      return [value, "#{ENV_VAR} environment variable"] if MODES.include?(value)
      [[LOCAL, "machine-local override"], [POLICY, "repository policy"]].each do |rel, label|
        path = File.join(root, rel)
        next unless File.file?(path)
        data = YAML.safe_load_file(path) || {}
        value = data.dig("guard", "mode").to_s.strip.downcase
        return [value, "#{label} (#{rel})"] if MODES.include?(value)
      rescue Psych::Exception
        next
      end
      [DEFAULT_MODE, "default"]
    end

    def initialize(root, plane: ControlPlane.new(root), git: Git.new(root), env: ENV)
      @root = File.expand_path(root)
      @plane = plane
      @git = git
      @env = env
    end

    # The change and skill whose permissions apply right now, or nil with
    # the reason nothing applies (no control plane, no branch record, a
    # finished change).
    def active
      return [nil, nil, ".ai/ is not installed here"] unless @plane.present?
      return [nil, nil, "not a git repository"] unless @git.repository?
      branch = @git.branch.to_s
      slug = [branch, branch.sub(%r{\Achange/}, "")].uniq.find { |c| File.exist?(File.join(@root, "changes", c, "metadata.yml")) }
      return [nil, nil, "no change record for branch '#{branch}'"] unless slug
      record = ChangeRecord.new(@root, slug, control_plane: @plane)
      status = record.metadata["status"].to_s
      return [record, nil, "change #{slug} is #{status}"] if %w[closed judged].include?(status)
      if record.exploring?
        definition = record.track_definition
        return [record, nil, "change #{slug} is exploring but its track names no skill"] unless definition&.skill
        return [record, @plane.skill(definition.skill), nil]
      end
      phase = @plane.phase(record.metadata["current_phase"].to_s)
      return [record, nil, "change #{slug} has current_phase '#{record.metadata['current_phase']}', not a lifecycle phase"] unless phase
      [record, @plane.skill(phase.skill), nil]
    rescue ArgumentError => e
      [nil, nil, e.message]
    end

    # Decides one tool call. `tool_input` is the hook payload's tool_input.
    # A panel member's session (SOFT_FOUNDRY_PANEL_MEMBER and _STAGE, set by
    # `phase run --panel`) is narrowed further, never widened.
    def decide(tool_name, tool_input)
      if (staged = own_draft_write(tool_name, tool_input))
        return staged
      end
      decision = decide_by_skill(tool_name, tool_input)
      return decision if decision.violation?
      narrow_for_panel(tool_name, tool_input, decision)
    end

    def decide_by_skill(tool_name, tool_input)
      record, skill, why = active
      return Decision.new(outcome: :allow, reason: why, skill: nil, paths: []) unless skill

      sets = permission_sets(skill, record.slug)
      case tool_name
      when *WRITE_TOOLS, *PATCH_TOOLS
        # Claude Code names the file; Codex sends an apply_patch (under
        # its own name or the Edit/Write aliases) whose paths are inside
        # the patch text carried in `command`.
        paths = if tool_input["file_path"] || tool_input["notebook_path"]
                  [relative(tool_input["file_path"] || tool_input["notebook_path"])]
                else
                  patch_paths(command_text(tool_input["command"])).map { |p| relative(p) }
                end.compact
        return Decision.new(outcome: :allow, reason: "no file path in the tool call", skill: skill.name, paths: []) if paths.empty?
        outside = paths.select { |p| p.start_with?("..") || p.start_with?("/") }
        return violation(skill, outside, "outside the repository; no skill may write there") unless outside.empty?
        denied = paths.select { |p| ControlPlane.match_any?(p, sets[:deny_write]) }
        return violation(skill, denied, "is in #{skill.name}'s deny_write set") unless denied.empty?
        unlisted = paths.reject { |p| ControlPlane.match_any?(p, sets[:write]) }
        return violation(skill, unlisted, "is not in #{skill.name}'s write set") unless unlisted.empty?
        Decision.new(outcome: :allow, reason: "in #{skill.name}'s write set", skill: skill.name, paths: paths)
      when *READ_TOOLS
        path = relative(tool_input["file_path"] || tool_input["target_file"])
        return Decision.new(outcome: :allow, reason: "no file path in the tool call", skill: skill.name, paths: []) unless path
        return violation(skill, [path], "is in #{skill.name}'s deny_read set") if ControlPlane.match_any?(path, sets[:deny_read])
        Decision.new(outcome: :allow, reason: "not denied to #{skill.name}", skill: skill.name, paths: [path])
      when *SHELL_TOOLS
        touched = shell_paths(command_text(tool_input["command"]))
        denied = touched.select { |p| ControlPlane.match_any?(p, sets[:deny_write]) || ControlPlane.match_any?(p, sets[:deny_read]) }
        return violation(skill, denied, "names a path #{skill.name} is denied (Bash is checked against deny sets only)") unless denied.empty?
        Decision.new(outcome: :allow, reason: "names no path denied to #{skill.name}", skill: skill.name, paths: touched)
      else
        Decision.new(outcome: :allow, reason: "tool #{tool_name} is not guarded", skill: skill.name, paths: [])
      end
    end

    # Appends a non-allow decision to the machine-local log. Never raises:
    # a guard that cannot log must still answer.
    def log(decision, mode:, tool_name:, now: Time.now)
      path = File.join(@root, LOG)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "a") do |f|
        f.puts "#{now.utc.iso8601} #{mode} #{tool_name} skill=#{decision.skill} paths=#{decision.paths.join(',')} #{decision.reason}"
      end
    rescue SystemCallError
      nil
    end

    private

    # The panel member and stage `phase run --panel` set for this session,
    # or nil. A member name the runner does not make is ignored, not trusted.
    def panel_context
      member = @env[Panel::MEMBER_ENV].to_s
      stage = @env[Panel::STAGE_ENV].to_s
      return nil unless member.match?(Panel::NAME) && Panel::STAGES.include?(stage)
      record, = active
      phase = record && @plane.phase(record.metadata["current_phase"].to_s)
      return nil unless phase
      phase_dir = "changes/#{record.slug}/#{phase.output}/"
      draft = @env[Panel::DRAFT_ENV].to_s
      { member: member, stage: stage, skill: record && active[1]&.name, phase_dir: phase_dir, base: "#{phase_dir}panel/",
        own: "#{phase_dir}panel/#{member}/", argument: "#{phase_dir}panel/ARGUMENT.md",
        draft: draft.empty? ? nil : File.expand_path(draft) }
    end

    # In the independent stage a member writes its draft outside the
    # repository, in the folder the runner named; that write is allowed
    # here, before the skill's rule that nothing outside the repository
    # may be written.
    def own_draft_write(tool_name, tool_input)
      return nil unless WRITE_TOOLS.include?(tool_name)
      ctx = panel_context
      return nil unless ctx && ctx[:stage] == "independent" && ctx[:draft]
      path = tool_input["file_path"].to_s
      return nil if path.empty?
      abs = File.expand_path(path, @root)
      return nil unless abs.start_with?("#{ctx[:draft]}/")
      Decision.new(outcome: :allow, reason: "panel member #{ctx[:member]}'s own draft folder", skill: ctx[:skill], paths: [abs])
    end

    # Independent stage: write only the member's own draft, and name no
    # other member's draft, ARGUMENT.md, or the phase's own files, with any
    # tool. Argument stage: write only ARGUMENT.md, and touch nothing else
    # in the phase folder from the shell. Consensus stage: the drafts and
    # the argument are frozen. Narrowing never widens a skill decision.
    def narrow_for_panel(tool_name, tool_input, decision)
      ctx = panel_context
      return decision unless ctx
      member, stage = ctx.values_at(:member, :stage)
      writes = WRITE_TOOLS.include?(tool_name) || PATCH_TOOLS.include?(tool_name)
      shell = SHELL_TOOLS.include?(tool_name)
      named = (decision.paths + mentioned_paths(tool_input)).uniq
      foreign_draft = ->(p) { p.start_with?(ctx[:base]) && !p.start_with?(ctx[:own]) }
      staged_elsewhere = ->(p) { p.include?(Panel::STAGING_PREFIX) && !(ctx[:draft] && File.expand_path(p, @root).start_with?("#{ctx[:draft]}/")) }
      bad, why =
        case stage
        when "independent"
          if writes
            [decision.paths.reject { |p| p.start_with?(ctx[:own]) }, "panel member #{member} may write only its own draft in the independent stage"]
          elsif shell
            [named.select { |p| p.start_with?(ctx[:phase_dir]) || staged_elsewhere.call(p) }, "panel member #{member} may not touch the phase's files from the shell in the independent stage"]
          else
            [named.select { |p| foreign_draft.call(p) || staged_elsewhere.call(p) || (p.start_with?(ctx[:phase_dir]) && !p.start_with?(ctx[:base]) && !READ_TOOLS.include?(tool_name)) },
             "panel member #{member} may not read another member's draft or ARGUMENT.md in the independent stage"]
          end
        when "argument"
          if writes
            [decision.paths.reject { |p| p == ctx[:argument] }, "panel member #{member} may write only #{ctx[:argument]} in the argument stage"]
          elsif shell
            [named.select { |p| p.start_with?(ctx[:phase_dir]) && p != ctx[:argument] }, "panel member #{member} may touch only #{ctx[:argument]} from the shell in the argument stage; read drafts with the read tool"]
          else
            [[], nil]
          end
        else
          if writes
            [decision.paths.select { |p| p.start_with?(ctx[:base]) }, "the drafts and ARGUMENT.md are frozen in the consensus stage"]
          elsif shell
            [named.select { |p| p.start_with?(ctx[:base]) }, "the drafts and ARGUMENT.md are frozen in the consensus stage; read them with the read tool"]
          else
            [[], nil]
          end
        end
      return decision if bad.empty?
      Decision.new(outcome: :violation, reason: why, skill: decision.skill, paths: bad)
    end

    # Repository-relative forms of every string in a tool's input that names
    # a path (a path, a glob, a search root), for tools the guard does not
    # otherwise know. Absolute paths outside the repository are kept as is.
    def mentioned_paths(tool_input)
      strings = []
      walk = ->(v) { v.is_a?(Hash) ? v.each_value { |x| walk.call(x) } : v.is_a?(Array) ? v.each { |x| walk.call(x) } : (strings << v if v.is_a?(String)) }
      walk.call(tool_input)
      strings.filter_map do |text|
        next if text.include?("\n") || text.length > 4096
        next unless text.include?("/")
        candidate = text.strip
        rel = relative(candidate)
        rel = "#{rel}/" if rel && File.directory?(File.join(@root, rel.to_s)) && !rel.end_with?("/")
        rel
      end
    end

    def violation(skill, paths, reason)
      Decision.new(outcome: :violation, reason: reason, skill: skill.name, paths: paths)
    end

    def permission_sets(skill, slug)
      %w[read write deny_read deny_write].to_h do |key|
        [key.to_sym, Array(skill.permissions[key]).flat_map { |p| @plane.expand(p, change: slug) }]
      end
    end

    # A path from the tool call, repository-relative. Paths outside the
    # repository keep a leading ".." or "/" so the caller can see it.
    def relative(path)
      return nil if path.nil? || path.to_s.strip.empty?
      abs = File.expand_path(path.to_s, @root)
      return abs unless abs.start_with?("#{@root}/") || abs == @root
      abs.delete_prefix("#{@root}/")
    end

    # A command as text. Codex may send `command` as an array of
    # arguments (["apply_patch", "<patch>"] or ["rm", "-rf", "x"]).
    def command_text(command)
      command.is_a?(Array) ? command.map(&:to_s).join(" ") : command.to_s
    end

    # Every path an apply_patch touches: added, updated, deleted, and the
    # target of a move. An empty result means the text is not a patch.
    def patch_paths(text)
      text.each_line.filter_map { |line| line.strip[PATCH_HEADER, 1] }.uniq
    end

    # Tokens of a shell command that name something in the repository:
    # existing files or directories, or path-shaped tokens (containing a
    # slash or starting with a dot) under the root. Redirections and
    # quotes are stripped. This is a heuristic, which is why Bash is only
    # ever checked against deny sets.
    def shell_paths(command)
      command.split(/[\s;|&()<>]+/).filter_map do |raw|
        token = raw.gsub(/\A["']+|["']+\z/, "").sub(/\A[<>]+/, "")
        next if token.empty? || token.start_with?("-") || token.match?(/\A[A-Za-z_][A-Za-z0-9_]*=/)
        next unless token.include?("/") || token.start_with?(".") || File.exist?(File.join(@root, token))
        rel = relative(token)
        next if rel.nil? || rel.start_with?("/") || rel.start_with?("..")
        rel
      end.uniq
    end
  end
end
