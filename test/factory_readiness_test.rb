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

# REQ-FR-002: the specification is locked on the gated track from the
# commit that recorded it, and evidence produced before a specification
# rerun is stale.
class GatedSpecificationLockTest < Minitest::Test
  include FoundryFixture

  def with_change
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c2")
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c2", control_plane: plane, branch: "change/c2")
      commit_all(dir, "scaffold c2")
      yield dir, plane, record, SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir))
    end
  end

  def check(gate, phase, name) = gate.evaluate(phase).checks.find { |c| c.name == name }

  def test_specification_is_locked_from_the_commit_that_recorded_it
    with_change do |dir, plane, record, gate|
      %w[intake discover specify].each { |p| complete_phase!(record, p, sha: head(dir)) }
      commit_all(dir, "specified")
      lock = head(dir)
      c = check(gate, "specify", "specification locked")
      assert_equal :pass, c.outcome, c.detail
      assert_includes c.detail, lock[0, 12]

      File.write(File.join(record.phase_dir(plane.phase("specify")), "requirements.yml"), "requirements: []\n")
      c = check(gate, "specify", "specification locked")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "requirements.yml"
      assert_includes c.detail, "rerun the specification phase"
      assert gate.evaluate("specify").failed?

      commit_all(dir, "edit the spec after the lock")
      assert_equal :fail, check(gate, "specify", "specification locked").outcome, "a committed edit is still an edit after the lock"
    end
  end

  def test_an_uncommitted_specification_is_not_locked_yet
    with_change do |dir, _plane, record, gate|
      %w[intake discover specify].each { |p| complete_phase!(record, p, sha: head(dir)) }
      c = check(gate, "specify", "specification locked")
      assert_equal :warn, c.outcome
      assert_includes c.detail, "not yet locked"
      refute gate.evaluate("specify").failed?
    end
  end

  def test_evidence_recorded_before_a_specification_rerun_is_stale
    with_change do |dir, plane, record, gate|
      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: head(dir)) } # intake..verify
      commit_all(dir, "through verification")
      refute gate.evaluate("verify").stale?, "evidence recorded with the specification in the same commit is current"
      assert_equal :pass, check(gate, "specify", "specification locked").outcome

      File.write(File.join(record.phase_dir(plane.phase("specify")), "requirements.yml"), "requirements: []\n")
      complete_phase!(record, "specify", sha: head(dir))
      commit_all(dir, "re-record the specification")
      assert_equal :pass, check(gate, "specify", "specification locked").outcome, "the rerun re-binds the lock"
      c = check(gate, "verify", "evidence current")
      assert_equal :fail, c.outcome
      assert_includes c.detail, "specification"
      assert gate.evaluate("verify").stale?
    end
  end
end
