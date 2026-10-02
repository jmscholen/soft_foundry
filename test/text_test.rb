# frozen_string_literal: true

require_relative "test_helper"

class TextTest < Minitest::Test
  include FoundryFixture

  def test_read_survives_a_us_ascii_default_external
    with_fixture_repo do |dir|
      path = File.join(dir, "zw.md")
      File.binwrite(path, "# x\n\nDo the\u200B thing\n")
      previous = Encoding.default_external
      Encoding.default_external = Encoding::US_ASCII
      text = SoftFoundry::Text.read(path)
      assert text.valid_encoding?
      assert_includes text, "\u200B"
      assert_silent { text.match?(/\bTBD\b/) }
    ensure
      Encoding.default_external = previous
    end
  end

  def test_gate_placeholder_check_reads_invisible_text_under_us_ascii
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c1", control_plane: plane)
      complete_phase!(record, "intake", sha: head(dir))
      request = File.join(record.phase_dir(plane.phase("intake")), "request.md")
      File.binwrite(request, File.binread(request) + "\nand\u200Bthis\n")
      previous = Encoding.default_external
      Encoding.default_external = Encoding::US_ASCII
      result = SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("intake")
      clean = result.checks.find { |c| c.name == "content clean" }
      assert_equal :fail, clean.outcome, result.checks.inspect
    ensure
      Encoding.default_external = previous if previous
    end
  end
end
