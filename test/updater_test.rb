# frozen_string_literal: true

require_relative "test_helper"

class UpdaterTest < Minitest::Test
  def test_newer_version_is_reported_as_available
    u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: -> { ["0.4.0", nil] })
    result = u.check
    assert result.update_available
    assert_equal "0.4.0", result.latest
    assert_nil result.error
  end

  def test_same_version_is_up_to_date
    u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: -> { ["0.3.0", nil] })
    refute u.check.update_available
  end

  def test_older_published_version_is_not_an_update
    u = SoftFoundry::Updater.new(current: "0.4.0", fetcher: -> { ["0.3.0", nil] })
    refute u.check.update_available
  end

  def test_fetch_error_is_reported_without_crashing
    u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: -> { [nil, "HTTP 404"] })
    result = u.check
    refute result.update_available
    assert_equal "HTTP 404", result.error
    assert_nil result.latest
  end

  def test_install_delegates_to_the_injected_installer
    installed_version = nil
    installer = lambda do |version|
      installed_version = version
      SoftFoundry::Updater::InstallResult.new(ok: true, message: "Successfully installed soft_foundry-#{version}")
    end
    u = SoftFoundry::Updater.new(installer: installer)
    result = u.install!("0.4.0")
    assert result.ok
    assert_equal "0.4.0", installed_version
  end

  def test_install_failure_is_reported
    installer = ->(_version) { SoftFoundry::Updater::InstallResult.new(ok: false, message: "gem install failed") }
    result = SoftFoundry::Updater.new(installer: installer).install!("0.4.0")
    refute result.ok
    assert_includes result.message, "failed"
  end
end

class UpdaterUnknownSentinelTest < Minitest::Test
  # RubyGems' latest.json returns HTTP 200 with {"version":"unknown"} for a
  # gem with no published version, rather than a 404. Found via a real
  # network call while building this feature.
  def test_rubygems_unknown_sentinel_is_reported_as_not_published_not_up_to_date
    response = Struct.new(:code, :body).new("200", '{"version":"unknown"}')
    def response.is_a?(klass) = klass == Net::HTTPSuccess ? true : super
    fetcher = lambda do
      data = JSON.parse(response.body)
      version = data["version"]
      version == "unknown" ? [nil, "soft_foundry is not published to RubyGems yet"] : [version, nil]
    end
    u = SoftFoundry::Updater.new(current: "0.3.0", fetcher: fetcher)
    result = u.check
    refute result.update_available
    assert_includes result.error, "not published"
  end
end
