# frozen_string_literal: true

require_relative "test_helper"

class MaturityDeepAssessTest < Minitest::Test
  include FoundryFixture

  # "true" is a real executable present on every POSIX PATH, so
  # available? passes genuinely without requiring claude to be installed;
  # the injected runner fully controls simulated execution regardless.
  def assessor(dir, runner:) = SoftFoundry::MaturityDeepAssess.new(dir, binary: "true", runner: runner)

  def test_available_is_false_for_an_unknown_binary
    refute SoftFoundry::MaturityDeepAssess.available?(binary: "definitely-not-a-real-binary-xyz")
  end

  def test_available_is_true_for_a_real_binary
    assert SoftFoundry::MaturityDeepAssess.available?(binary: "true")
  end

  def test_missing_binary_raises_target_error_before_running
    with_fixture_repo do |dir|
      called = false
      runner = ->(_argv, _dir, _timeout) { called = true; [true, "ok"] }
      a = SoftFoundry::MaturityDeepAssess.new(dir, binary: "definitely-not-a-real-binary-xyz", runner: runner)
      assert_raises(SoftFoundry::TargetError) { a.run! }
      refute called
    end
  end

  def test_success_writes_and_updates_repository_yml
    with_fixture_repo do |dir|
      runner = lambda do |_argv, target_dir, _timeout|
        File.write(File.join(target_dir, ".ai/repository.yml"), "version: 1\nrepository: {assessed: true}\n")
        [true, "maturity: level 3\n"]
      end
      result = assessor(dir, runner: runner).run!
      assert result.ok, result.message
      assert_includes result.message, "level 3"
    end
  end

  def test_timeout_is_reported_distinctly_from_a_failed_exit
    with_fixture_repo do |dir|
      timeout_runner = ->(_argv, _dir, _timeout) { [nil, ""] }
      result = assessor(dir, runner: timeout_runner).run!
      refute result.ok
      assert_includes result.message, "timed out"
    end
  end

  def test_nonzero_exit_is_reported_as_failure_not_timeout
    with_fixture_repo do |dir|
      failing_runner = ->(_argv, _dir, _timeout) { [false, "some error"] }
      result = assessor(dir, runner: failing_runner).run!
      refute result.ok
      refute_includes result.message, "timed out"
      assert_includes result.message, "some error"
    end
  end

  def test_exit_ok_but_no_file_written_is_a_failure
    with_fixture_repo do |dir|
      noop_runner = ->(_argv, _dir, _timeout) { [true, "did nothing"] }
      FileUtils.rm_f(File.join(dir, ".ai/repository.yml"))
      result = assessor(dir, runner: noop_runner).run!
      refute result.ok
      assert_includes result.message, "was not written"
    end
  end

  def test_exit_ok_but_file_unchanged_is_a_failure
    with_fixture_repo do |dir|
      path = File.join(dir, ".ai/repository.yml")
      File.utime(Time.now - 10, Time.now - 10, path)
      old_mtime = File.mtime(path)
      stale_runner = ->(_argv, _dir, _timeout) { [true, "did nothing new"] }
      result = assessor(dir, runner: stale_runner).run!
      refute result.ok
      assert_includes result.message, "was not updated"
      assert_equal old_mtime, File.mtime(path)
    end
  end

  def test_argv_is_a_clean_array_not_a_shell_string
    with_fixture_repo do |dir|
      captured_argv = nil
      runner = lambda do |argv, _dir, _timeout|
        captured_argv = argv
        [true, "ok"]
      end
      File.utime(Time.now - 10, Time.now - 10, File.join(dir, ".ai/repository.yml"))
      assessor(dir, runner: runner).run!
      assert_equal 3, captured_argv.size
      assert_equal "true", captured_argv[0]
      assert_equal "-p", captured_argv[1]
      assert_includes SoftFoundry::MaturityDeepAssess::PROMPT, "repository-discovery"
    end
  end
end
