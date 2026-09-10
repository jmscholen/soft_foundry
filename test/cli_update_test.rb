# frozen_string_literal: true

require_relative "test_helper"

class CLIUpdateTest < Minitest::Test
  include FoundryFixture

  def run_cli(dir, args, updater)
    out = StringIO.new
    code = SoftFoundry::CLI.new(["update", *args], out: out, err: out, root: dir, updater: updater).run
    [code, out.string]
  end

  def test_up_to_date_reports_and_writes_nothing
    with_fixture_repo do |dir|
      u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: -> { ["0.3.0", nil] })
      code, out = run_cli(dir, [], u)
      assert_equal 0, code, out
      assert_includes out, "up to date"
    end
  end

  def test_update_available_without_yes_only_reports
    with_fixture_repo do |dir|
      installer_called = false
      u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: -> { ["0.4.0", nil] }, installer: ->(_v) { installer_called = true })
      code, out = run_cli(dir, [], u)
      assert_equal 0, code, out
      assert_includes out, "a newer version is available"
      assert_includes out, "--yes"
      refute installer_called
    end
  end

  def test_yes_installs_when_update_available
    with_fixture_repo do |dir|
      installed = nil
      installer = lambda do |v|
        installed = v
        SoftFoundry::Updater::InstallResult.new(ok: true, message: "Successfully installed soft_foundry-#{v}")
      end
      u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: -> { ["0.4.0", nil] }, installer:)
      code, out = run_cli(dir, ["--yes"], u)
      assert_equal 0, code, out
      assert_equal "0.4.0", installed
      assert_includes out, "updated to 0.4.0"
    end
  end

  def test_yes_with_nothing_to_install_does_not_call_installer
    with_fixture_repo do |dir|
      installer_called = false
      u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: -> { ["0.3.0", nil] }, installer: ->(_v) { installer_called = true })
      code, out = run_cli(dir, ["--yes"], u)
      assert_equal 0, code, out
      assert_includes out, "up to date"
      refute installer_called
    end
  end

  def test_install_failure_is_reported_with_nonzero_exit
    with_fixture_repo do |dir|
      installer = ->(_v) { SoftFoundry::Updater::InstallResult.new(ok: false, message: "permission denied") }
      u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: -> { ["0.4.0", nil] }, installer:)
      code, out = run_cli(dir, ["--yes"], u)
      refute_equal 0, code
      assert_includes out, "permission denied"
      assert_includes out, "install failed"
    end
  end

  def test_fetch_error_is_reported_with_nonzero_exit
    with_fixture_repo do |dir|
      u = SoftFoundry::Updater.new(fetcher: -> { [nil, "network unreachable"] })
      code, out = run_cli(dir, [], u)
      refute_equal 0, code
      assert_includes out, "network unreachable"
    end
  end

  def test_unknown_option_is_a_usage_error
    with_fixture_repo do |dir|
      u = SoftFoundry::Updater.new(fetcher: -> { ["0.3.0", nil] })
      code, out = run_cli(dir, ["--bogus"], u)
      assert_equal 1, code
      assert_includes out, "unknown option"
    end
  end
end
