# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "errors"
require_relative "safe_write"

module SoftFoundry
  # Installs the hooks Soft Foundry relies on: a git pre-commit hook that
  # runs `soft-foundry ci`, and a Claude Code PreToolUse hook that runs
  # `soft-foundry guard` so a coding shell's tool calls are checked against
  # the active skill's permissions at runtime.
  class Hooks
    MARKER = "# soft-foundry:pre-commit"
    # A checkout of Soft Foundry itself runs its own code, not whatever
    # older gem happens to be on PATH; every other repository uses the gem.
    SCRIPT = <<~SH
      #!/bin/sh
      #{MARKER}
      # Validates the .ai/ control plane and every change record before commit.
      if [ -x exe/soft-foundry ] && [ -f lib/soft_foundry.rb ]; then
        exec ruby -Ilib exe/soft-foundry ci
      elif command -v soft-foundry >/dev/null 2>&1; then
        exec soft-foundry ci
      else
        echo "soft-foundry not found; skipping control-plane checks" >&2
      fi
    SH

    def self.install(root)
      hooks_dir = File.join(root, ".git", "hooks")
      raise "#{root} is not a git repository" unless File.directory?(File.join(root, ".git"))
      FileUtils.mkdir_p(hooks_dir)
      path = File.join(hooks_dir, "pre-commit")
      if File.exist?(path) && !File.read(path).include?(MARKER)
        raise "#{path} already exists and was not installed by soft-foundry; merge `soft-foundry ci` into it manually"
      end
      File.write(path, SCRIPT)
      File.chmod(0o755, path)
      path
    end

    # The Claude Code guard hook. It lives in `.claude/settings.json`
    # (shared with the repository) or `.claude/settings.local.json`
    # (machine-local). Soft Foundry's entry is recognised by GUARD_ID in its
    # command, so reinstalling replaces it and uninstalling removes only
    # it; every other key and hook in the file is kept byte for byte in
    # meaning, if not in formatting.
    GUARD_ID = "soft-foundry:guard"
    GUARD_MATCHER = "Edit|Write|MultiEdit|NotebookEdit|Read|Bash"
    GUARD_COMMAND = "# #{GUARD_ID}\nif [ -x exe/soft-foundry ] && [ -f lib/soft_foundry.rb ]; then ruby -Ilib exe/soft-foundry guard; elif command -v soft-foundry >/dev/null 2>&1; then soft-foundry guard; fi"

    def self.claude_settings_path(root, local: false)
      File.join(root, ".claude", local ? "settings.local.json" : "settings.json")
    end

    # Codex reads project hooks from .codex/hooks.json in the same shape
    # (hooks.PreToolUse[].matcher / hooks[].command, the payload on stdin,
    # exit 2 to refuse). Its shell tool is `Bash`; file edits arrive as
    # `apply_patch` (also matched by the Edit and Write aliases) with the
    # patch text in the command. Codex runs a project hook only after the
    # person has reviewed and trusted it with /hooks inside Codex.
    CODEX_GUARD_MATCHER = "Bash|apply_patch|Edit|Write"

    def self.codex_hooks_path(root) = File.join(root, ".codex", "hooks.json")

    def self.install_claude(root, local: false) = install_into(claude_settings_path(root, local: local), GUARD_MATCHER)
    def self.uninstall_claude(root, local: false) = uninstall_from(claude_settings_path(root, local: local))
    def self.install_codex(root) = install_into(codex_hooks_path(root), CODEX_GUARD_MATCHER)
    def self.uninstall_codex(root) = uninstall_from(codex_hooks_path(root))

    def self.install_into(path, matcher)
      settings = read_settings(path)
      hooks = (settings["hooks"] ||= {})
      raise TargetError, "#{path}: hooks is not an object" unless hooks.is_a?(Hash)
      entries = Array(hooks["PreToolUse"]).reject { |e| guard_entry?(e) }
      entries << { "matcher" => matcher, "hooks" => [{ "type" => "command", "command" => GUARD_COMMAND }] }
      hooks["PreToolUse"] = entries
      write_settings(path, settings)
      path
    end

    def self.uninstall_from(path)
      return nil unless File.file?(path)
      settings = read_settings(path)
      hooks = settings["hooks"]
      return nil unless hooks.is_a?(Hash) && hooks["PreToolUse"].is_a?(Array)
      before = hooks["PreToolUse"].size
      hooks["PreToolUse"] = hooks["PreToolUse"].reject { |e| guard_entry?(e) }
      return nil if hooks["PreToolUse"].size == before
      hooks.delete("PreToolUse") if hooks["PreToolUse"].empty?
      settings.delete("hooks") if hooks.empty?
      write_settings(path, settings)
      path
    end

    # Whether the guard is installed for Claude Code in this repository, and where.
    def self.claude_installed?(root)
      [false, true].filter_map { |local| installed_at(claude_settings_path(root, local: local)) }.first
    end

    def self.codex_installed?(root) = installed_at(codex_hooks_path(root))

    def self.installed_at(path)
      return nil unless File.file?(path)
      entries = read_settings(path).dig("hooks", "PreToolUse")
      path if entries.is_a?(Array) && entries.any? { |e| guard_entry?(e) }
    rescue TargetError
      nil
    end

    def self.guard_entry?(entry)
      entry.is_a?(Hash) && Array(entry["hooks"]).any? { |h| h.is_a?(Hash) && h["command"].to_s.include?(GUARD_ID) }
    end

    # --- the session hook (user level) -----------------------------------
    #
    # `soft-foundry session log` as a UserPromptSubmit hook in the person's
    # own configuration for every agent, so every session on the machine
    # is recorded in the session ledger whichever repository it runs in.
    # The command prints nothing and always succeeds: hook output can
    # reach an agent's context, and a fault must never block a prompt.
    SESSIONS_ID = "soft-foundry:sessions"
    SESSION_AGENTS = %w[claude codex grok].freeze
    SESSION_TIMEOUT = 10

    def self.session_command(shell)
      "# #{SESSIONS_ID}\ncommand -v soft-foundry >/dev/null 2>&1 && soft-foundry session log --shell #{shell} >/dev/null 2>&1; exit 0"
    end

    # Where each agent reads user-level hooks. Grok also reads Claude's
    # file; the ledger records a double fire once, keyed by session.
    def self.session_hook_paths(home)
      {
        "claude" => File.join(home, ".claude", "settings.json"),
        "codex" => File.join(home, ".codex", "hooks.json"),
        "grok" => File.join(home, ".grok", "hooks", "soft-foundry-sessions.json")
      }
    end

    # The find-session skill: Claude Code's skill folder (which Grok also
    # reads) and the folder Codex discovers user skills in.
    def self.session_skill_paths(home)
      {
        "claude" => File.join(home, ".claude", "skills", "find-session", "SKILL.md"),
        "codex" => File.join(home, ".agents", "skills", "find-session", "SKILL.md")
      }
    end

    FIND_SESSION_SKILL = <<~MD
      ---
      name: find-session
      description: Find and resume past Claude Code, Codex, or Grok sessions. Use when the user asks which agent or folder handled a topic, mentions earlier agent work, wants to locate a past conversation, or asks for a resume command.
      ---

      <!-- #{SESSIONS_ID}: written by `soft-foundry hooks install --sessions`; removed by `hooks uninstall --sessions` -->

      # Find an agent session

      1. Run `soft-foundry sessions <distinctive words>` (add `--change SLUG`, `--phase PHASE`, or `--agent claude|codex|grok` when the user names one; `--json` for data). Words must all match, case-insensitively, across prompts, folder, branch, and change.
      2. Ignore the current lookup request itself: a match counts only when the words come from earlier substantive work, not from a request to find a session.
      3. Trust the status word: `resumable`, `folder missing`, or `transcript missing`. Do not call a session resumable otherwise.
      4. If nothing matches, retry with fewer or different words. Then search the agents' own stores: `grok sessions search <words>`, Codex `~/.codex/sessions/**/rollout-*.jsonl`, Claude Code `~/.claude/projects/**/*.jsonl` (search with `rg -i -l`, and ignore tool output that merely repeats the words).
      5. Return up to five matches, strongest first, with date, agent, folder, branch, change and phase, and the exact `resume:` command as printed. State any uncertainty.

      `soft-foundry resume <change> [phase]` prints the single newest command for a change.

      Never edit the ledger, and never launch a resume command unless the user explicitly asks.
    MD

    # Installs the session hook for every agent and the find-session skill.
    # Returns [[action, path, note]] for the caller to report.
    def self.install_sessions(home)
      report = session_hook_paths(home).map do |shell, path|
        settings = read_settings(path)
        hooks = (settings["hooks"] ||= {})
        raise TargetError, "#{path}: hooks is not an object" unless hooks.is_a?(Hash)
        entries = Array(hooks["UserPromptSubmit"]).reject { |e| session_entry?(e) }
        entries << { "hooks" => [{ "type" => "command", "command" => session_command(shell), "timeout" => SESSION_TIMEOUT }] }
        hooks["UserPromptSubmit"] = entries
        write_settings(path, settings)
        [:installed, path, shell]
      end
      session_skill_paths(home).each_value do |path|
        if File.exist?(path) && !File.read(path).include?(SESSIONS_ID)
          report << [:skipped, path, "not written by soft-foundry"]
          next
        end
        SafeWrite.ensure_directory!(File.dirname(path))
        SafeWrite.write(path, FIND_SESSION_SKILL)
        report << [:skill, path, nil]
      end
      report
    end

    def self.uninstall_sessions(home)
      removed = session_hook_paths(home).filter_map do |shell, path|
        next nil unless File.file?(path)
        settings = read_settings(path)
        hooks = settings["hooks"]
        next nil unless hooks.is_a?(Hash) && hooks["UserPromptSubmit"].is_a?(Array)
        before = hooks["UserPromptSubmit"].size
        hooks["UserPromptSubmit"] = hooks["UserPromptSubmit"].reject { |e| session_entry?(e) }
        next nil if hooks["UserPromptSubmit"].size == before
        hooks.delete("UserPromptSubmit") if hooks["UserPromptSubmit"].empty?
        settings.delete("hooks") if hooks.empty?
        if shell == "grok" && settings.empty?
          File.delete(path)
        else
          write_settings(path, settings)
        end
        [:removed, path, shell]
      end
      session_skill_paths(home).each_value do |path|
        next unless File.file?(path) && !File.symlink?(path) && File.read(path).include?(SESSIONS_ID)
        File.delete(path)
        Dir.rmdir(File.dirname(path)) if Dir.empty?(File.dirname(path))
        removed << [:skill, path, nil]
      end
      removed
    end

    # Agents whose user-level configuration carries the session hook.
    def self.sessions_installed(home)
      session_hook_paths(home).filter_map do |shell, path|
        next nil unless File.file?(path)
        entries = read_settings(path).dig("hooks", "UserPromptSubmit")
        shell if entries.is_a?(Array) && entries.any? { |e| session_entry?(e) }
      rescue TargetError
        nil
      end
    end

    def self.session_entry?(entry)
      entry.is_a?(Hash) && Array(entry["hooks"]).any? { |h| h.is_a?(Hash) && h["command"].to_s.include?(SESSIONS_ID) }
    end

    def self.read_settings(path)
      return {} unless File.exist?(path) || File.symlink?(path)
      raise TargetError, "#{path} is a symlink; refusing to write through it" if File.symlink?(path)
      data = JSON.parse(File.read(path))
      raise TargetError, "#{path}: expected a JSON object" unless data.is_a?(Hash)
      data
    rescue JSON::ParserError => e
      raise TargetError, "#{path} is not valid JSON: #{e.message}"
    end

    def self.write_settings(path, settings)
      SafeWrite.ensure_directory!(File.dirname(path))
      SafeWrite.write(path, JSON.pretty_generate(settings) + "\n")
    end
  end
end
