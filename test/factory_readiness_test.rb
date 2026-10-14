# frozen_string_literal: true

require_relative "test_helper"

# changes/factory-readiness: REQ-FR-001 (UTF-8 reads).
class Utf8ReadsTest < Minitest::Test
  include FoundryFixture

  # The process locale decides Encoding.default_external; a C locale makes
  # it US-ASCII, and File.read then yields strings that raise on the first
  # regex match against a non-ASCII byte.
  def with_ascii_default
    saved = Encoding.default_external
    verbose = $VERBOSE
    $VERBOSE = nil
    Encoding.default_external = Encoding::US_ASCII
    yield
  ensure
    Encoding.default_external = saved
    $VERBOSE = verbose
  end

  def with_intake(text)
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c1", control_plane: plane)
      complete_phase!(record, "intake", sha: head(dir))
      File.binwrite(File.join(record.phase_dir(plane.phase("intake")), "request.md"), text)
      yield dir, record, SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
    end
  end

  def test_gate_and_advisory_read_record_files_as_utf8_whatever_the_locale
    with_intake("# Intake\n\ninit → change new → gate\n".b) do |_dir, record, gate|
      with_ascii_default do
        result = gate.evaluate("intake")
        refute result.failed?, result.checks.map { |c| "#{c.name}: #{c.detail}" }.join("\n")
        assert_kind_of Array, SoftFoundry::Advisory.new(record).notices
      end
    end
  end

  def test_invalid_bytes_are_scrubbed_not_raised
    with_intake("# Intake\n\xFF\xFE broken TBD here\n".b) do |_dir, _record, gate|
      with_ascii_default do
        result = gate.evaluate("intake")
        check = result.checks.find { |c| c.name == "no placeholders" }
        assert_equal :fail, check.outcome, "the placeholder is still found after scrubbing"
        assert_includes check.detail, "request.md"
      end
    end
  end

  def test_read_text_returns_utf8_under_any_locale
    Dir.mktmpdir do |dir|
      path = File.join(dir, "t.md")
      File.binwrite(path, "caf\xC3\xA9 \xFF".b)
      with_ascii_default do
        text = SoftFoundry.read_text(path)
        assert_equal Encoding::UTF_8, text.encoding
        assert text.valid_encoding?
        assert_includes text, "café"
      end
    end
  end
end
