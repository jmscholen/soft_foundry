# frozen_string_literal: true

require "time"
require_relative "errors"
require_relative "text"
require_relative "change_record"
require_relative "gate"

module SoftFoundry
  # The released state: a change whose lifecycle is finished and judged
  # approving, but which still owes real-world confirmations. `closed`
  # stays the only end state. Release records what is owed as items;
  # discharge records each as confirmed; `change close` ends the record.
  #
  # Neither command can be run from inside a phase-run session, so a phase
  # cannot release or discharge on its own behalf.
  class Release
    MARKER = "SOFT_FOUNDRY_PHASE"
    RELEASABLE = %w[intake in_progress judged].freeze
    APPROVING = %w[APPROVED APPROVED_WITH_RESIDUAL_RISK].freeze

    def initialize(root, plane:, git:, record:)
      @root = File.expand_path(root)
      @plane = plane
      @git = git
      @record = record
    end

    # `specs` are "ID=DESCRIPTION" strings. Every refusal raises before
    # anything is written.
    def release(specs, env: ENV, now: Time.now)
      refuse_marker!(env, "change release")
      @record.locked { release_locked(specs, now) }
    end

    def release_locked(specs, now)
      refuse_status!
      judgment!
      lifecycle!
      gates!
      given = parse(specs)
      raise ArgumentError, "--item is required: name at least one thing still owed, as --item ID=DESCRIPTION (for example --item GOLIVE-1='switch the flag on')" if given.empty?
      carried = @record.undischarged_acceptance.filter_map do |item|
        next unless item.is_a?(Hash) && item["id"].to_s.strip != ""

        { "id" => item["id"].to_s, "description" => item["description"].to_s.strip.empty? ? "carried from the final judgment's undischarged conditions" : item["description"].to_s, "from" => "judgment" }
      end
      clash = (given + carried).map { |i| i["id"] }.tally.find { |_, n| n > 1 }
      raise ArgumentError, "item id #{clash.first} appears twice (a final-judgment undischarged condition keeps its own id); use a different id" if clash

      block = { "at" => now.utc.iso8601, "commit" => (@git.repository? ? @git.head_sha : nil), "items" => given + carried }
      @record.update_metadata do |m|
        m["status"] = "released"
        m["release"] = block
      end
      block
    end
    private :release_locked

    def discharge(id, note:, env: ENV, now: Time.now)
      refuse_marker!(env, "change discharge")
      status = @record.metadata["status"].to_s
      raise TargetError, "#{@record.slug} is #{status}, not released; only a released change has items to discharge (release it with `soft-foundry change release`)" unless status == "released"
      text = Text.free_text!(note, "--note")
      item = @record.release_items.find { |i| i["id"].to_s == id.to_s }
      raise TargetError, "#{@record.slug} has no release item #{id.to_s.inspect}; open items: #{open_ids}" unless item
      raise TargetError, "release item #{id} is already discharged; open items: #{open_ids}" if item["discharged_at"]

      commit = @git.repository? ? @git.head_sha : nil
      @record.update_metadata do |m|
        target = Array(m.dig("release", "items")).find { |i| i.is_a?(Hash) && i["id"].to_s == id.to_s }
        target["discharged_at"] = now.utc.iso8601
        target["discharge_commit"] = commit
        target["discharge_note"] = text
      end
      @record.open_release_items
    end

    # Problems with a released record's `release` block, each a sentence
    # naming the defect. `judgment_undischarged` are the ids the final
    # judgment left undischarged, which the block must carry. Empty for a
    # record that is not released.
    def self.lint(meta, judgment_undischarged: [])
      return [] unless meta.is_a?(Hash) && meta["status"].to_s == "released"

      block = meta["release"]
      return ["released record's release block is missing (run `soft-foundry change release`, or fix the record)"] if block.nil?
      return ["released record's release block is not a mapping"] unless block.is_a?(Hash)

      problems = []
      problems << "release block has no 'at' time" if block["at"].to_s.strip.empty?
      problems << "release block has no 'commit'" unless block.key?("commit")
      items = block["items"]
      return problems + ["release block has no items (a released record names what is still owed)"] unless items.is_a?(Array) && !items.empty?

      ids = []
      items.each_with_index do |item, i|
        unless item.is_a?(Hash)
          problems << "release item #{i + 1} is not a mapping"
          next
        end
        id = item["id"].to_s
        problems << "release item #{i + 1} has no id" if id.strip.empty?
        problems << "release item #{id.inspect} has control characters in its id" if id.match?(/\p{Cntrl}/)
        problems << "release item #{id.inspect} has no description" if item["description"].to_s.strip.empty?
        ids << id unless id.empty?
      end
      ids.tally.each { |id, n| problems << "release block has a duplicate id #{id}" if n > 1 }
      (Array(judgment_undischarged).map(&:to_s) - ids).each do |id|
        problems << "final judgment's undischarged item #{id} is not carried in the release block"
      end
      problems
    end

    private

    def open_ids
      ids = @record.open_release_items.map { |i| i["id"] }
      ids.empty? ? "none" : ids.join(", ")
    end

    def refuse_marker!(env, command)
      return unless env.key?(MARKER)

      raise TargetError, "#{command} is refused inside a phase-run session (#{MARKER} is set): a phase may not decide what a change still owes; ask the person running the change to run it"
    end

    def refuse_status!
      status = @record.metadata["status"].to_s
      return if RELEASABLE.include?(status)

      advice = case status
               when "closed" then "a closed change has nothing left to release"
               when "released" then "already released; discharge its items with `soft-foundry change discharge ID --note TEXT`"
               when "exploring" then "an exploring change is not finished; accept it with `soft-foundry change vet` and run the hardening phases first"
               when "awaiting_human" then "a person must record the decision under human_decisions in metadata.yml first"
               else "only a record that is #{RELEASABLE.join(', ')} can be released"
               end
      raise TargetError, "#{@record.slug} is #{status}, so it cannot be released: #{advice}"
    end

    def judgment!
      status = @record.judgment_status
      raise TargetError, "cannot release #{@record.slug}: 14-judgment is #{status || 'missing'}; a release rests on a complete final judgment (run `soft-foundry phase run judge`)" unless status == "complete"

      outcome = @record.judgment_outcome
      if outcome.nil?
        raise TargetError, "cannot release #{@record.slug}: the outcome in 14-judgment/final.md is not exactly one of #{@plane.judgments.join(', ')}; the judgment must state it"
      end
      return if APPROVING.include?(outcome)

      raise TargetError, "cannot release #{@record.slug}: the final judgment is #{outcome}; only #{APPROVING.join(' or ')} can be released"
    end

    def lifecycle!
      return if @record.reached_lifecycle_end?

      raise TargetError, "cannot release #{@record.slug}: it has not reached the end of its lifecycle (a required phase is still pending and not skipped-with-rationale)"
    end

    def gates!
      failing = Gate.new(@record, git: @git).evaluate_all.select(&:failed?)
      return if failing.empty?

      raise TargetError, "cannot release #{@record.slug}: the gate fails for #{failing.map { |r| r.phase.output }.join(', ')}; run `soft-foundry change status` for the checks, redo the work, then release"
    end

    def parse(specs)
      given = specs.map do |spec|
        id, sep, description = spec.to_s.partition("=")
        raise ArgumentError, "--item takes ID=DESCRIPTION (an id of capital letters, digits, and hyphens, an equals sign, then what is owed)" if sep.empty?

        { "id" => Text.id!(id, "item id"), "description" => Text.free_text!(description, "the description of item #{id}") }
      end
      clash = given.map { |i| i["id"] }.tally.find { |_, n| n > 1 }
      raise ArgumentError, "item id #{clash.first} is given twice; ids must be unique" if clash

      given
    end
  end
end
