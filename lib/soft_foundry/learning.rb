# frozen_string_literal: true

require "yaml"
require_relative "control_plane"
require_relative "change_record"
require_relative "safe_write"

module SoftFoundry
  # Instincts: what a change taught, as one-line triggers with an action, a
  # confidence score, and evidence, written by the learning phase into
  # 15-learning/instincts.yml. `learn list` shows them across records;
  # `learn promote` copies those above the threshold into
  # .ai/rules/learned.md, the governance path for a proposed rule: it
  # happens on a change branch, through that change's record, never by an
  # agent applying its own lesson to the rules it works under.
  module Learning
    Instinct = Data.define(:id, :trigger, :action, :confidence, :domain, :evidence, :change) do
      def evidence_words = evidence.map { |e| e.is_a?(Hash) ? e.values.map(&:to_s).join(" ") : e.to_s }
    end

    ID = /\A[a-z0-9]+(-[a-z0-9]+)*\z/
    POLICY = ".ai/policies/learning.yml"
    RULES = ".ai/rules/learned.md"
    DEFAULT_MIN_CONFIDENCE = 0.8
    HEADER = <<~MD
      # Learned Rules

      Instincts promoted from change records by `soft-foundry learn promote`: each
      entry names the change that learned it, its confidence when promoted, and the
      evidence in that record. Implementation and exploration load this file with
      the baseline rules. Edit it only through a change record, the way it was
      written.
    MD

    module_function

    # Problems with one instinct entry, in words; empty when valid.
    def problems(entry, seen_ids)
      return ["entry is not a mapping"] unless entry.is_a?(Hash)
      problems = []
      id = entry["id"].to_s
      problems << "id '#{id}' is not kebab-case" unless id.match?(ID)
      problems << "duplicate id '#{id}'" if seen_ids.include?(id)
      problems << "trigger is empty" if entry["trigger"].to_s.strip.empty?
      problems << "action is empty" if entry["action"].to_s.strip.empty?
      c = entry["confidence"]
      problems << "confidence '#{c}' is not a number between 0 and 1" unless c.is_a?(Numeric) && c >= 0 && c <= 1
      problems << "evidence is empty" if Array(entry["evidence"]).empty?
      problems.map { |p| id.empty? ? p : "#{id}: #{p}".sub(/\A#{Regexp.escape(id)}: (id|duplicate)/, '\1') }
    end

    # [instincts, problems] read from one record's learning phase.
    def read(record)
      phase = record.control_plane.phase("learn")
      path = phase && File.join(record.phase_dir(phase), "instincts.yml")
      return [[], ["instincts.yml is missing"]] unless path && File.file?(path)
      data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
      list = data["instincts"]
      return [[], ["instincts is not a list"]] unless list.is_a?(Array)
      seen = []
      problems = []
      instincts = list.filter_map do |entry|
        ps = problems(entry, seen)
        seen << entry["id"].to_s if entry.is_a?(Hash)
        next problems.concat(ps) && nil unless ps.empty?
        Instinct.new(id: entry["id"], trigger: entry["trigger"].to_s, action: entry["action"].to_s, confidence: entry["confidence"].to_f,
                     domain: entry["domain"].to_s, evidence: Array(entry["evidence"]), change: record.slug)
      end
      [instincts, problems]
    rescue Psych::Exception => e
      [[], ["instincts.yml is not valid YAML: #{e.message}"]]
    end

    # Every valid instinct in every record (closed ones included: a lesson
    # outlives the change), highest confidence first.
    def all(root, plane)
      base = File.join(root, "changes")
      return [] unless File.directory?(base)
      Dir.glob("**/metadata.yml", base: base).map { |p| File.dirname(p) }.sort.flat_map do |slug|
        record = ChangeRecord.new(root, slug, control_plane: plane)
        read(record).first
      rescue ArgumentError
        []
      end.sort_by { |i| [-i.confidence, i.change, i.id] }
    end

    def min_confidence(root)
      path = File.join(root, POLICY)
      return DEFAULT_MIN_CONFIDENCE unless File.file?(path)
      value = (YAML.safe_load_file(path) || {}).dig("promote", "min_confidence")
      value.is_a?(Numeric) ? value.to_f : DEFAULT_MIN_CONFIDENCE
    rescue Psych::Exception
      DEFAULT_MIN_CONFIDENCE
    end

    def promoted_ids(root)
      path = File.join(root, RULES)
      return [] unless File.file?(path)
      File.read(path).scan(/^## (\S+)\s*$/).flatten
    end

    def section(instinct)
      <<~MD

        ## #{instinct.id}

        - **When:** #{instinct.trigger}
        - **Do:** #{instinct.action}
        - **Confidence:** #{format('%.2f', instinct.confidence)} (from change #{instinct.change}#{instinct.domain.empty? ? '' : ", domain #{instinct.domain}"}; evidence: #{instinct.evidence_words.join(', ')})
      MD
    end

    # Appends the given instincts to learned.md, creating it with the
    # header if absent. The caller decides which; this only writes.
    def promote!(root, instincts)
      path = File.join(root, RULES)
      body = File.file?(path) ? File.read(path) : HEADER
      body = body.rstrip + "\n" + instincts.map { |i| section(i) }.join
      SafeWrite.ensure_directory!(File.dirname(path))
      SafeWrite.write(path, body)
      path
    end
  end
end
