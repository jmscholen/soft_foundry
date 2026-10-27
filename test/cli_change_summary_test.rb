# frozen_string_literal: true

require_relative "lifecycle_fixture"

# `soft-foundry change summary [slug]`: where a change is now, from recorded
# files only, one fact per line with a stable prefix.
class CliChangeSummaryTest < Minitest::Test
  include LifecycleFixture

  UPTO_VERIFY = %w[intake discover specify threat_model plan implement verify].freeze

  def edit_handoff(record, id, &block) = record.update_handoff(record.control_plane.phase(id), &block)

  def test_prints_prefixed_lines_for_a_mixed_record
    with_lifecycle_record(complete: UPTO_VERIFY, current_phase: "evaluate") do |dir, record|
      edit_handoff(record, "implement") { |h| h["findings"] = [{ "id" => "F1", "severity" => "minor", "summary" => "s" }, { "id" => "F2", "severity" => "major", "summary" => "t" }] }
      edit_handoff(record, "evaluate") { |h| h.merge!("status" => "blocked", "blocking" => ["needs a person"]) }
      record.update_metadata { |m| m["status"] = "awaiting_human" }
      before = tree_bytes(dir, ".")
      code, out, err = run_cli(dir, "change", "summary", "c1")
      assert_equal 0, code, err
      lines = out.lines.map(&:chomp)
      assert_includes lines, "change: c1"
      assert(lines.any? { |l| l.start_with?("phase: evaluate") })
      assert_includes lines, "phase-status: verify complete"
      assert_includes lines, "phase-status: evaluate blocked"
      assert_includes lines, "phase-status: attack pending"
      assert_includes lines, "findings: implement 2 (major 1, minor 1)"
      assert_includes lines, "blocking: evaluate: needs a person"
      assert(lines.any? { |l| l.start_with?("owed:") && l.include?("awaiting_human") })
      assert(lines.all? { |l| l.match?(/\A(change|phase|phase-status|findings|blocking|owed|note):/) }, out)
      assert_equal before.reject { |k, _| k.start_with?(".soft-foundry") }, tree_bytes(dir, ".").reject { |k, _| k.start_with?(".soft-foundry") }, "nothing written"
    end
  end

  def test_defaults_to_the_current_branch_and_says_none_when_nothing_blocks
    with_lifecycle_record(complete: UPTO_VERIFY, current_phase: "evaluate") do |dir, _record|
      code, out, = run_cli(dir, "change", "summary")
      assert_equal 0, code
      assert_includes out, "blocking: none"
      assert_includes out, "findings: none"
    end
  end

  def test_unknown_slug_is_refused_naming_the_known_changes
    with_lifecycle_record do |dir, _record|
      code, out, err = run_cli(dir, "change", "summary", "nope")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/c1/, out + err)
      code, = run_cli(dir, "change", "summary", "../x")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
    end
  end

  def test_an_unreadable_handoff_is_shown_and_the_rest_still_prints
    with_lifecycle_record(complete: UPTO_VERIFY, current_phase: "evaluate") do |dir, record|
      File.write(record.handoff_path(record.control_plane.phase("discover")), "status: [unclosed\n")
      big = record.handoff_path(record.control_plane.phase("specify"))
      File.write(big, "status: complete\nnotes: #{'a' * 300_000}\n")
      code, out, = run_cli(dir, "change", "summary", "c1")
      assert_equal 0, code
      assert_includes out, "phase-status: discover unreadable"
      assert_includes out, "phase-status: specify unreadable"
      assert_includes out, "phase-status: verify complete"
      assert_match(/note: discover .*(YAML|syntax|parse)/i, out)
    end
  end

  def test_an_alias_bomb_is_unreadable_not_expanded
    with_lifecycle_record(complete: UPTO_VERIFY, current_phase: "evaluate") do |dir, record|
      File.write(record.handoff_path(record.control_plane.phase("discover")), "a: &a [1]\nb: *a\nstatus: complete\n")
      _, out, = run_cli(dir, "change", "summary", "c1")
      assert_includes out, "phase-status: discover unreadable"
    end
  end

  def test_recorded_text_cannot_forge_lines_or_emit_escapes
    with_lifecycle_record(complete: UPTO_VERIFY, current_phase: "evaluate") do |dir, record|
      edit_handoff(record, "evaluate") { |h| h.merge!("status" => "blocked", "blocking" => ["x\nphase-status: judge complete\e[31m\r"]) }
      _, out, = run_cli(dir, "change", "summary", "c1")
      refute_includes out, "\e"
      refute_includes out, "\r"
      assert_equal 1, out.lines.count { |l| l.start_with?("phase-status: judge") }
      assert_includes out, "<U+001B>"
    end
  end

  def test_open_release_items_are_owed
    with_finished_record_released do |dir, _record|
      _, out, = run_cli(dir, "change", "summary", "c1")
      assert_match(/^owed: release item REL-1/, out)
    end
  end

  def with_finished_record_released
    with_lifecycle_record(complete: UPTO_VERIFY, current_phase: "evaluate") do |dir, record|
      record.update_metadata do |m|
        m["status"] = "released"
        m["release"] = { "released_at" => "2026-10-01T00:00:00Z", "items" => [{ "id" => "REL-1", "description" => "watch the rollout" }] }
      end
      yield dir, record
    end
  end

  def test_no_styling_and_ascii_words_when_not_a_tty
    with_lifecycle_record(complete: UPTO_VERIFY, current_phase: "evaluate") do |dir, _record|
      _, out, = run_cli(dir, "change", "summary", "c1", env: { "NO_COLOR" => "1" })
      refute_match(/\e\[/, out)
    end
  end

  def test_it_never_runs_the_gate
    with_lifecycle_record(complete: UPTO_VERIFY, current_phase: "evaluate") do |dir, _record|
      calls = 0
      original = SoftFoundry::Gate.method(:new)
      SoftFoundry::Gate.define_singleton_method(:new) { |*| calls += 1; raise "gate must not run" }
      begin
        code, = run_cli(dir, "change", "summary", "c1")
        assert_equal 0, code
      ensure
        SoftFoundry::Gate.define_singleton_method(:new, original)
      end
      assert_equal 0, calls
    end
  end
end
