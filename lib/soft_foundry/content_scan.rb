# frozen_string_literal: true

require "yaml"
require_relative "control_plane"

module SoftFoundry
  # The control plane and the change records are inputs an agent reads,
  # and anyone who can open a pull request may have written them. This
  # scan reads them the way an attacker would want them read: for text a
  # person cannot see (invisible Unicode), secrets that should never be
  # committed, phrases that try to override an agent's instructions, and
  # commands that fetch and execute remote code. Invisible text and
  # secrets are errors everywhere. Override phrases and fetch-and-execute
  # are errors under .ai/policies/ and warnings elsewhere, because a rule
  # or a threat model may quote an attack as an example. A line carrying
  # the allow marker is exempt from secrets, override phrases, and
  # fetch-and-execute (a documented example key, a quoted attack), never
  # from invisible text, for which there is no legitimate use in a file
  # an agent reads.
  module ContentScan
    Finding = Data.define(:path, :line, :kind, :level, :detail)

    ALLOW = "soft-foundry:scan-allow"
    POLICY_PREFIX = ".ai/policies/"
    TEXT_EXTENSIONS = %w[.md .yml .yaml .txt .log .json .toml .rb .sh .csv].freeze

    INVISIBLE = {
      "​" => "U+200B zero width space", "‌" => "U+200C zero width non-joiner", "‍" => "U+200D zero width joiner",
      "⁠" => "U+2060 word joiner", "﻿" => "U+FEFF byte order mark", "­" => "U+00AD soft hyphen",
      "‪" => "U+202A left-to-right embedding", "‫" => "U+202B right-to-left embedding", "‬" => "U+202C pop directional formatting",
      "‭" => "U+202D left-to-right override", "‮" => "U+202E right-to-left override",
      "⁦" => "U+2066 left-to-right isolate", "⁧" => "U+2067 right-to-left isolate", "⁨" => "U+2068 first strong isolate", "⁩" => "U+2069 pop directional isolate"
    }.freeze
    INVISIBLE_RE = Regexp.union(INVISIBLE.keys + [/[\u{E0000}-\u{E007F}]/])

    SECRETS = {
      "AWS access key id" => /\bAKIA[0-9A-Z]{16}\b/,
      "OpenAI-style key" => /\bsk-[A-Za-z0-9_-]{20,}\b/,
      "GitHub token" => /\bgh[pousr]_[A-Za-z0-9]{36,}\b/,
      "Slack token" => /\bxox[baprs]-[A-Za-z0-9-]{10,}\b/,
      "Google API key" => /\bAIza[0-9A-Za-z_-]{35}\b/,
      "private key block" => /-----BEGIN (?:RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY(?: BLOCK)?-----/
    }.freeze

    OVERRIDE = [
      /\bignore\s+(?:all\s+|any\s+)?(?:previous|prior|above|earlier|preceding)\s+(?:instructions|rules|directions|guidance)\b/i,
      /\bdisregard\s+(?:all\s+|any\s+)?(?:the\s+|your\s+)?(?:previous|prior|above|earlier|system)?\s*(?:instructions|rules|directions|guidance)\b/i,
      /\boverride\s+(?:the\s+|your\s+|all\s+)?(?:rules|instructions|policy|policies|guard)\b/i,
      /\byou\s+are\s+now\s+(?:a|an|in)\b/i,
      /\bpretend\s+(?:you\s+are|to\s+be)\b/i,
      /\b(?:do\s+not|don't|never)\s+(?:tell|inform|mention\s+(?:this\s+)?to)\s+the\s+user\b/i,
      /\bhide\s+this\s+from\s+the\s+user\b/i,
      /\bnew\s+system\s+prompt\s*:/i
    ].freeze

    FETCH_EXEC = [
      /\b(?:curl|wget|fetch)\b[^|\n]*\|\s*(?:sudo\s+)?(?:sh|bash|zsh|ksh|dash|python[0-9.]*|ruby|node|perl)\b/i,
      /\b(?:sh|bash|zsh)\s+-c\s+["']?\$\((?:curl|wget)\b/i,
      /\beval\s+["']?\$\((?:curl|wget)\b/i,
      /\bpowershell\b[^\n]*\b(?:iex|Invoke-Expression)\b[^\n]*\b(?:iwr|Invoke-WebRequest|DownloadString)\b/i,
      /\bpowershell\b[^\n]*\b(?:iwr|Invoke-WebRequest|DownloadString)\b[^\n]*\b(?:iex|Invoke-Expression)\b/i
    ].freeze

    module_function

    # Findings for one file's text. `path` is repository-relative and
    # decides the level of override and fetch-and-execute findings.
    def scan_text(path, text)
      policy = path.to_s.start_with?(POLICY_PREFIX)
      findings = []
      text.to_s.scrub("?").each_line.with_index(1) do |line, number|
        line.scan(INVISIBLE_RE) do |m|
          findings << Finding.new(path: path, line: number, kind: "invisible", level: :error, detail: INVISIBLE.fetch(m) { format("U+%04X format character", m.ord) })
        end
        next if line.include?(ALLOW)
        SECRETS.each do |name, re|
          findings << Finding.new(path: path, line: number, kind: "secret", level: :error, detail: "#{name} shaped string") if line.match?(re)
        end
        level = policy ? :error : :warning
        if OVERRIDE.any? { |re| line.match?(re) }
          findings << Finding.new(path: path, line: number, kind: "override", level: level, detail: "instruction-override phrase#{policy ? ' in a policy file' : ' (a rule quoting an attack may add the allow marker)'}")
        end
        if FETCH_EXEC.any? { |re| line.match?(re) }
          findings << Finding.new(path: path, line: number, kind: "fetch_exec", level: level, detail: "fetches and executes remote code#{policy ? ' in a policy file' : ' (a rule quoting an attack may add the allow marker)'}")
        end
      end
      findings
    end

    # Findings across repository-relative paths; unreadable or binary
    # files are skipped rather than guessed at. Findings the repository's
    # allowlist (.ai/policies/content-scan.yml) covers are dropped: each
    # entry names path globs, optionally the kinds and a substring the
    # line must contain, and a reason. Invisible text is never allowed.
    def scan_paths(root, paths, allow: allowlist(root))
      paths.flat_map do |rel|
        abs = File.join(root, rel)
        next [] unless File.file?(abs) && !File.symlink?(abs) && text_file?(abs)
        text = File.binread(abs).force_encoding("UTF-8")
        lines = text.scrub("?").lines
        scan_text(rel, text).reject { |f| allowed?(f, lines[f.line - 1].to_s, allow) }
      end
    end

    POLICY_FILE = ".ai/policies/content-scan.yml"
    ALLOW_KINDS = %w[secret override fetch_exec].freeze

    def allowlist(root)
      path = File.join(root, POLICY_FILE)
      return [] unless File.file?(path)
      data = YAML.safe_load_file(path) || {}
      Array(data["allow"]).select { |e| e.is_a?(Hash) }
    rescue Psych::Exception
      []
    end

    def allowed?(finding, line, allow)
      return false if finding.kind == "invisible"
      allow.any? do |entry|
        paths = Array(entry["paths"]).map(&:to_s)
        kinds = Array(entry["kinds"]).map(&:to_s)
        match = entry["match"].to_s
        !paths.empty? && ControlPlane.match_any?(finding.path, paths) &&
          (kinds.empty? || kinds.include?(finding.kind)) &&
          (match.empty? || line.include?(match))
      end
    end

    # Problems with the allowlist's shape, for `check`.
    def allowlist_problems(root)
      path = File.join(root, POLICY_FILE)
      return [] unless File.file?(path)
      data = YAML.safe_load_file(path) || {}
      entries = data["allow"]
      return ["#{POLICY_FILE}: allow must be a list"] unless entries.nil? || entries.is_a?(Array)
      Array(entries).each_with_index.flat_map do |entry, i|
        next ["#{POLICY_FILE}: allow[#{i}] is not a mapping"] unless entry.is_a?(Hash)
        problems = []
        problems << "#{POLICY_FILE}: allow[#{i}] names no paths" if Array(entry["paths"]).empty?
        problems << "#{POLICY_FILE}: allow[#{i}] has no reason" if entry["reason"].to_s.strip.empty?
        bad = Array(entry["kinds"]).map(&:to_s) - ALLOW_KINDS
        problems << "#{POLICY_FILE}: allow[#{i}] kinds #{bad.join(', ')} are not allowable (#{ALLOW_KINDS.join(', ')}; invisible is never allowed)" unless bad.empty?
        problems
      end
    rescue Psych::Exception => e
      ["#{POLICY_FILE} is not valid YAML: #{e.message}"]
    end

    # Everything an agent reads as instructions: .ai/ and the pointer files.
    def control_plane_paths(root)
      files = Dir.glob(".ai/**/*", File::FNM_DOTMATCH, base: root).select { |rel| File.file?(File.join(root, rel)) }
      files += %w[AGENTS.md CLAUDE.md].select { |f| File.file?(File.join(root, f)) }
      files.sort
    end

    def record_paths(root, slug)
      Dir.glob("changes/#{slug}/**/*", File::FNM_DOTMATCH, base: root).select { |rel| File.file?(File.join(root, rel)) }.sort
    end

    def phase_paths(root, record, phase)
      base = record.phase_dir(phase).delete_prefix("#{File.expand_path(root)}/")
      Dir.glob("#{base}/**/*", File::FNM_DOTMATCH, base: root).select { |rel| File.file?(File.join(root, rel)) }.sort
    end

    def text_file?(abs)
      return true if TEXT_EXTENSIONS.include?(File.extname(abs).downcase) || File.extname(abs).empty?
      sample = File.binread(abs, 512)
      !sample.include?("\0")
    end
  end
end
