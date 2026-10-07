# frozen_string_literal: true

require "json"
require "time"
require "yaml"
require "date"
require "fileutils"
require "shellwords"
require_relative "errors"
require_relative "git"
require_relative "content_scan"

module SoftFoundry
  # A machine-local index of every coding session (Claude Code, Codex,
  # Grok) a prompt hook has seen: where it ran, what change and phase it
  # was on, and how to get back into it. One JSON object per line, one
  # line per agent and session ID, rewritten in place on later prompts.
  #
  # It is an index, not a backup: a session can be resumed only while its
  # agent still has the transcript. Nothing here leaves the machine, and
  # the file lives outside every repository so no committed record can
  # pick it up.
  class SessionLedger
    ENV_VAR = "SOFT_FOUNDRY_SESSIONS"
    AGENTS = %w[claude codex grok].freeze
    # Session IDs are pasted into a shell inside a resume command, so only
    # plain identifiers are ever recorded.
    ID = /\A[A-Za-z0-9_-]{1,128}\z/.freeze
    PROMPT_LIMIT = 140
    MAX_INPUT = 1_048_576
    CONTROL = /[\u0000-\u001f\u007f-\u009f]/.freeze
    RESUME = {
      "claude" => "claude --resume",
      "codex" => "codex resume",
      "grok" => "grok --resume"
    }.freeze

    def self.default_path(env = ENV, home: Dir.home)
      value = env[ENV_VAR].to_s
      value.empty? ? File.join(home, ".soft-foundry", "sessions.jsonl") : value
    end

    # Grok sends a camelCase hookEventName beside the snake_case keys, and
    # also runs hooks it finds in Claude's settings files, so its payload,
    # not the hook entry's --shell, says which agent it is.
    def self.agent_for(payload, shell)
      return "grok" if payload.key?("hookEventName")
      AGENTS.include?(shell.to_s) ? shell.to_s : "claude"
    end

    # Both the folder and the ID are quoted: lookup only returns entries
    # `record` could have written, but the command is pasted into a shell.
    def self.resume_command(entry)
      "cd #{Shellwords.escape(entry['cwd'].to_s)} && #{RESUME.fetch(entry['agent'], RESUME['claude'])} #{Shellwords.escape(entry['session_id'].to_s)}"
    end

    # Whether a line read back from the ledger is one `record` could have
    # written. Anyone who can write the file can add others; they are kept
    # in it but never looked up.
    def self.trusted?(entry)
      entry["session_id"].is_a?(String) && entry["session_id"].match?(ID) && AGENTS.include?(entry["agent"]) && entry["cwd"].is_a?(String)
    end

    # Whether the session can still be resumed from here, as a word.
    def self.status(entry)
      return "folder missing" unless File.directory?(entry["cwd"].to_s)
      transcript = entry["transcript"].to_s
      return "transcript missing" if !transcript.empty? && !File.exist?(transcript)
      "resumable"
    end

    def initialize(path, now: -> { Time.now })
      @path = path
      @now = now
    end

    attr_reader :path

    # Records one prompt-hook payload. Returns the entry written, or nil
    # when the payload is not a session this ledger can record. Raises
    # only on file-system refusals; the hook command swallows those.
    def record(payload, shell:)
      return nil unless payload.is_a?(Hash)
      id = (payload["session_id"] || payload["sessionId"]).to_s
      return nil unless id.match?(ID)
      cwd = text(payload["cwd"] || payload["workspaceRoot"])
      return nil if cwd.empty?
      agent = self.class.agent_for(payload, shell)
      stamp = @now.call.utc.iso8601
      prompt = excerpt(payload["prompt"])
      place = whereabouts(cwd)
      transcript = text(payload["transcript_path"] || payload["transcriptPath"])

      update do |lines|
        index = lines.index { |l| l.is_a?(Hash) && l["agent"] == agent && l["session_id"] == id }
        entry = index ? lines[index] : { "agent" => agent, "session_id" => id, "first_at" => stamp, "first_prompt" => prompt }
        entry.merge!("cwd" => cwd, **place, "last_at" => stamp, "latest_prompt" => prompt)
        entry["transcript"] = transcript unless transcript.empty?
        entry["transcript"] ||= nil
        index ? lines[index] = entry : lines << entry
        entry
      end
    end

    # Every entry that parses and could have come from `record`, oldest
    # line first.
    def entries
      return [] unless File.file?(@path)
      File.foreach(@path).filter_map do |line|
        data = JSON.parse(line)
        data if data.is_a?(Hash) && self.class.trusted?(data)
      rescue JSON::ParserError
        nil
      end
    end

    # Entries matching every word (case-insensitive, across prompts,
    # folder, branch, and change) and every filter, newest first.
    def search(words: [], change: nil, phase: nil, agent: nil)
      needles = words.map(&:downcase)
      entries.select do |e|
        next false if change && e["change"] != change
        next false if phase && e["phase"] != phase
        next false if agent && e["agent"] != agent
        hay = e.values_at("first_prompt", "latest_prompt", "cwd", "branch", "change", "repo").compact.join(" ").downcase
        needles.all? { |w| hay.include?(w) }
      end.sort_by { |e| e["last_at"].to_s }.reverse
    end

    def latest(change:, phase: nil, agent: nil) = search(change: change, phase: phase, agent: agent).first

    private

    # Runs the block over the ledger's lines (parsed hashes, or the raw
    # string for a line that does not parse, which is kept as it was)
    # under an exclusive lock held from read to rewrite, then replaces the
    # file atomically. The lock is a sibling file because the rename
    # replaces the ledger's inode.
    def update
      dir = File.dirname(@path)
      raise TargetError, "#{dir} is a symlink; refusing to use it" if File.symlink?(dir)
      FileUtils.mkdir_p(dir, mode: 0o700)
      File.chmod(0o700, dir) if File.stat(dir).owned?
      raise TargetError, "#{@path} is a symlink; refusing to write through it" if File.symlink?(@path)
      File.open("#{@path}.lock", File::RDWR | File::CREAT | File::NOFOLLOW, 0o600) do |lock|
        lock.flock(File::LOCK_EX)
        raise TargetError, "#{@path} is a symlink; refusing to write through it" if File.symlink?(@path)
        lines = File.file?(@path) ? File.readlines(@path, chomp: true).reject(&:empty?).map { |l| parse(l) } : []
        result = yield lines
        tmp = "#{@path}.#{Process.pid}.tmp"
        File.open(tmp, File::WRONLY | File::CREAT | File::TRUNC | File::NOFOLLOW, 0o600) do |f|
          lines.each { |l| f.puts(l.is_a?(Hash) ? JSON.generate(l) : l) }
        end
        File.rename(tmp, @path)
        result
      end
    rescue Errno::ELOOP => e
      raise TargetError, "refusing to write #{@path}: #{e.message}"
    end

    def parse(line)
      data = JSON.parse(line)
      data.is_a?(Hash) ? data : line
    rescue JSON::ParserError
      line
    end

    # Repository root, branch, and the change and phase its record names.
    def whereabouts(cwd)
      none = { "repo" => nil, "branch" => nil, "change" => nil, "phase" => nil }
      return none unless File.directory?(cwd)
      git = Git.new(cwd)
      top = git.toplevel
      return none unless top
      branch = git.branch
      slug = [branch, branch.to_s.sub(%r{\Achange/}, "")].compact.uniq.find do |c|
        c.match?(%r{\A[A-Za-z0-9][A-Za-z0-9._/-]*\z}) && !c.include?("..") && File.file?(File.join(top, "changes", c, "metadata.yml"))
      end
      phase = slug && begin
        YAML.safe_load_file(File.join(top, "changes", slug, "metadata.yml"), permitted_classes: [Time, Date])&.fetch("current_phase", nil)
      rescue Psych::Exception, SystemCallError
        nil
      end
      { "repo" => top, "branch" => text(branch), "change" => slug, "phase" => phase && text(phase) }
    end

    # Whitespace collapsed, control characters gone, secret shapes masked,
    # cut to PROMPT_LIMIT characters.
    def excerpt(value)
      flat = value.to_s.gsub(/\s+/, " ").gsub(CONTROL, "").strip
      ContentScan::SECRETS.each_value { |re| flat = flat.gsub(re, "[masked]") }
      flat.length > PROMPT_LIMIT ? "#{flat[0, PROMPT_LIMIT]}…" : flat
    end

    def text(value) = value.to_s.gsub(CONTROL, "")
  end
end
