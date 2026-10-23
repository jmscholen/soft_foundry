# frozen_string_literal: true

require_relative "lifecycle_fixture"

# `change release`, `change discharge`, `change close` on a released
# record, and `ci` over merged released changes.
class CliChangeReleaseTest < Minitest::Test
  include FinishedFixture

  def test_release_prints_one_fact_per_line_and_exits_zero
    with_finished_record do |dir, record|
      code, out, err = run_cli(dir, "change", "release", "c1", "--item", "GOLIVE-1=switch the flag on")
      assert_equal 0, code, err
      assert_equal ["c1: released", "released: c1: 1 open item(s): GOLIVE-1"], out.lines.map(&:chomp).first(2)
      assert_equal "released", record.metadata["status"]
      assert_predicate out, :ascii_only?
    end
  end

  def test_release_defaults_to_the_current_branchs_change
    with_finished_record do |dir, record|
      code, out, err = run_cli(dir, "change", "release", "--item", "A=a")
      assert_equal 0, code, out + err
      assert_equal "released", record.metadata["status"]
    end
  end

  def test_release_refusals_exit_one_say_what_to_do_and_write_nothing
    with_finished_record do |dir, _record|
      before = tree_bytes(dir)
      [
        [%w[release c1], /--item/],
        [%w[release c1 --item A=a --item A=b], /duplicate|twice/],
        [%w[release c1 --item lower=x], /lower/],
        [%w[release c1 --item A=], /description/],
        [%w[release c1 --item NOEQUALS], /ID=DESCRIPTION/],
        [%w[release c1 --item A=a --bogus], /unknown option/]
      ].each do |args, pattern|
        code, out, err = run_cli(dir, "change", *args)
        assert_equal SoftFoundry::CLI::EXIT_TARGET, code, args.inspect
        assert_match pattern, out + err, args.inspect
      end
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_a_blocked_judgment_is_refused_naming_it
    with_finished_record(outcome: "BLOCKED") do |dir, _record|
      code, out, err = run_cli(dir, "change", "release", "c1", "--item", "A=a")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/BLOCKED/, out + err)
    end
  end

  def test_release_discharge_close_sequence
    with_finished_record(merge: true) do |dir, record|
      code, = run_cli(dir, "change", "release", "c1", "--item", "A=first", "--item", "B=second")
      assert_equal 0, code
      code, out, err = run_cli(dir, "change", "close", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/open item.*A, B/, out + err)
      assert_match(/change discharge/, out + err)
      code, out, err = run_cli(dir, "change", "discharge", "A", "--note", "seen in production", "--change", "c1")
      assert_equal 0, code, out + err
      assert_includes out, "c1: discharged A"
      assert_includes out, "released: c1: 1 open item(s): B"
      code, out, err = run_cli(dir, "change", "close", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/\bB\b/, out + err)
      refute_match(/open item.*\bA\b,/, out + err)
      run_cli(dir, "change", "discharge", "B", "--note", "checked", "--change", "c1")
      code, out, err = run_cli(dir, "change", "close", "c1")
      assert_equal 0, code, out + err
      assert_equal "closed", record.metadata["status"]
    end
  end

  def test_close_force_overrides_open_items
    with_finished_record(merge: true) do |dir, record|
      run_cli(dir, "change", "release", "c1", "--item", "A=first")
      code, out, err = run_cli(dir, "change", "close", "c1", "--force")
      assert_equal 0, code, out + err
      assert_equal "closed", record.metadata["status"]
    end
  end

  def test_discharge_refusals
    with_finished_record do |dir, _record|
      code, out, err = run_cli(dir, "change", "discharge", "A", "--note", "n")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/not released/, out + err)
      run_cli(dir, "change", "release", "c1", "--item", "A=a")
      before = tree_bytes(dir)
      [%w[discharge ZZ --note n], %w[discharge A], ["discharge", "A", "--note", ""], %w[discharge]].each do |args|
        code, = run_cli(dir, "change", *args)
        assert_equal SoftFoundry::CLI::EXIT_TARGET, code, args.inspect
      end
      assert_equal before, tree_bytes(dir)
    end
  end

  def test_the_session_marker_refuses_release_and_discharge_through_the_cli
    with_finished_record do |dir, record|
      before = tree_bytes(dir)
      code, out, err = run_cli(dir, "change", "release", "c1", "--item", "A=a", env: { "SOFT_FOUNDRY_PHASE" => "review" })
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/phase-run session/, out + err)
      assert_equal before, tree_bytes(dir)
      run_cli(dir, "change", "release", "c1", "--item", "A=a")
      before = tree_bytes(dir)
      code, = run_cli(dir, "change", "discharge", "A", "--note", "n", env: { "SOFT_FOUNDRY_PHASE" => "review" })
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_equal before, tree_bytes(dir)
      assert_equal 1, record.open_release_items.size
    end
  end

  def test_carried_judgment_items_are_discharged_through_the_one_list_then_close_needs_no_confirm
    with_finished_record(merge: true, undischarged: %w[U-1]) do |dir, record|
      run_cli(dir, "change", "release", "c1", "--item", "A=a")
      code, out, err = run_cli(dir, "change", "close", "c1")
      assert_equal SoftFoundry::CLI::EXIT_TARGET, code
      assert_match(/A, U-1/, out + err)
      run_cli(dir, "change", "discharge", "A", "--note", "x", "--change", "c1")
      run_cli(dir, "change", "discharge", "U-1", "--note", "observed", "--change", "c1")
      code, out, err = run_cli(dir, "change", "close", "c1")
      assert_equal 0, code, out + err
      assert_equal "closed", record.metadata["status"]
      assert_equal [], record.undischarged_acceptance
      assert_equal %w[U-1], record.judgment_evidence["discharged"].map { |i| i["id"] }
    end
  end

  # --- ci -------------------------------------------------------------------------

  def test_ci_still_fails_a_merged_change_that_is_neither_closed_nor_released
    with_finished_record(merge: true) do |dir, _record|
      code, out = cli(dir, "ci")
      assert_equal 2, code, out
      assert_includes out, "not 'closed'"
    end
  end

  def test_ci_passes_a_merged_released_change_with_open_items_and_says_what_is_owed
    with_finished_record(merge: true, undischarged: []) do |dir, _record|
      sh(dir, "git", "checkout", "-q", "change/c1")
      run_cli(dir, "change", "release", "c1", "--item", "GOLIVE-1=flag", "--item", "GOLIVE-2=dashboards")
      commit_all(dir, "release")
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/c1", "-m", "merge release")
      code, out = cli(dir, "ci")
      assert_equal 0, code, out
      assert_includes out, "released: c1: 2 open item(s): GOLIVE-1, GOLIVE-2"
      assert_match(/^advisory: c1 is released with 2 open item\(s\)/, out)
    end
  end

  def test_ci_fails_a_merged_released_change_with_every_item_discharged
    with_finished_record(merge: true) do |dir, _record|
      sh(dir, "git", "checkout", "-q", "change/c1")
      run_cli(dir, "change", "release", "c1", "--item", "GOLIVE-1=flag")
      run_cli(dir, "change", "discharge", "GOLIVE-1", "--note", "done")
      commit_all(dir, "release and discharge")
      sh(dir, "git", "checkout", "-q", "main")
      sh(dir, "git", "merge", "-q", "--no-ff", "change/c1", "-m", "merge release")
      code, out = cli(dir, "ci")
      assert_equal 2, code, out
      assert_includes out, "run `soft-foundry change close c1`"
    end
  end

  def test_check_fails_a_released_record_with_a_missing_or_malformed_block
    with_finished_record do |dir, record|
      record.update_metadata { |m| m["status"] = "released" }
      code, out = cli(dir, "check")
      assert_equal 2, code, out
      assert_match(/changes\/c1\/metadata.yml: released record has no release block/, out)
      record.update_metadata { |m| m["release"] = { "at" => "t", "commit" => "c", "items" => [] } }
      code, out = cli(dir, "check")
      assert_equal 2, code
      assert_match(/no items/, out)
      record.update_metadata { |m| m["release"]["items"] = [{ "id" => "A", "description" => "a" }, { "id" => "A", "description" => "b" }] }
      _, out = cli(dir, "check")
      assert_match(/duplicate id A/, out)
    end
  end

  def test_check_requires_judgment_undischarged_ids_to_be_in_the_release
    with_finished_record(undischarged: %w[U-1]) do |dir, record|
      run_cli(dir, "change", "release", "c1", "--item", "A=a")
      record.update_metadata { |m| m["release"]["items"].reject! { |i| i["id"] == "U-1" } }
      _, out = cli(dir, "check")
      assert_match(/U-1/, out)
    end
  end
end
