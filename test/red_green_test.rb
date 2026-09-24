# frozen_string_literal: true

require_relative "test_helper"

# RED and GREEN checkpoint commits as commit-bound verification evidence:
# a check in 06-verification/tests.yml may name the commit at which its
# test existed and failed (red_commit) and the test file (test_path); the
# gate verifies the shape of that claim against git, and the advisory
# names a feature or fix verified with no RED evidence at all.
class RedGreenTest < Minitest::Test
  include FoundryFixture

  # A change with a RED commit (test added, code untouched) followed by a
  # GREEN commit (code changed), verification complete at GREEN.
  def with_red_green(check_overrides = {}, type: "feature")
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      sh(dir, "git", "checkout", "-qb", "change/c1")
      cli(dir, "change", "new", "c1")
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane)
      meta = File.join(record.dir, "metadata.yml")
      File.write(meta, File.read(meta).sub(/^type: TBD.*$/, "type: #{type}"))
      commit_all(dir, "record")

      File.write(File.join(dir, "test", "feature_test.rb"), "# expects puts 2\n")
      commit_all(dir, "RED: feature test")
      red = head(dir)

      File.write(File.join(dir, "lib", "app.rb"), "puts 2\n")
      commit_all(dir, "GREEN: feature")
      green = head(dir)

      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: green) } # intake..verify
      write_check!(record, plane, { "red_commit" => red, "test_path" => "test/feature_test.rb" }.merge(check_overrides))
      yield dir, plane, record, red, green
    end
  end

  def write_check!(record, plane, fields)
    path = File.join(record.phase_dir(plane.phase("verify")), "tests.yml")
    data = YAML.safe_load_file(path)
    data["checks"] = [{ "id" => "CHECK-001", "kind" => "tests", "command" => "rake test", "result" => "pass", "evidence" => "evidence/tests.log", "criteria" => ["AC-001"] }.merge(fields)]
    File.write(path, YAML.dump(data))
  end

  def red_check(dir, record)
    SoftFoundry::Gate.new(record, git: SoftFoundry::Git.new(dir)).evaluate("verify").checks.find { |c| c.name == "red evidence" }
  end

  def test_a_red_commit_that_precedes_green_with_the_test_present_passes
    with_red_green do |dir, _plane, record, red, _green|
      check = red_check(dir, record)
      refute_nil check, "the verification gate should carry a red evidence check"
      assert_equal :pass, check.outcome, check.detail
      assert_includes check.detail, "CHECK-001"
      assert_includes check.detail, red[0, 12]
    end
  end

  def test_red_commit_equal_to_the_verified_commit_fails
    with_red_green do |dir, plane, record, _red, green|
      write_check!(record, plane, "red_commit" => green, "test_path" => "test/feature_test.rb")
      check = red_check(dir, record)
      assert_equal :fail, check.outcome
      assert_includes check.detail, "CHECK-001"
      assert_includes check.detail, "is the verified commit itself"
    end
  end

  def test_red_commit_that_is_not_an_ancestor_fails
    with_red_green do |dir, plane, record, _red, _green|
      sh(dir, "git", "checkout", "-qb", "elsewhere")
      File.write(File.join(dir, "test", "other_test.rb"), "# other\n")
      commit_all(dir, "unrelated")
      other = head(dir)
      sh(dir, "git", "checkout", "-q", "change/c1")
      write_check!(record, plane, "red_commit" => other, "test_path" => "test/other_test.rb")
      check = red_check(dir, record)
      assert_equal :fail, check.outcome
      assert_includes check.detail, "not an ancestor"
    end
  end

  def test_test_path_absent_at_the_red_commit_fails
    with_red_green("test_path" => "test/nope_test.rb") do |dir, _plane, record, _red, _green|
      check = red_check(dir, record)
      assert_equal :fail, check.outcome
      assert_includes check.detail, "test/nope_test.rb"
      assert_includes check.detail, "does not exist at"
    end
  end

  def test_no_code_change_between_red_and_green_fails
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      sh(dir, "git", "checkout", "-qb", "change/c1")
      cli(dir, "change", "new", "c1")
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: plane)
      commit_all(dir, "record")
      File.write(File.join(dir, "test", "feature_test.rb"), "# test\n")
      commit_all(dir, "RED")
      red = head(dir)
      File.write(File.join(dir, "docs", "note.md"), "docs only\n") rescue (FileUtils.mkdir_p(File.join(dir, "docs")); File.write(File.join(dir, "docs", "note.md"), "docs only\n"))
      commit_all(dir, "docs only")
      green = head(dir)
      plane.phases.take(7).each { |p| complete_phase!(record, p.id, sha: green) }
      write_check!(record, plane, "red_commit" => red, "test_path" => "test/feature_test.rb")
      check = red_check(dir, record)
      assert_equal :fail, check.outcome
      assert_includes check.detail, "no APP or INFRA change between"
    end
  end

  def test_malformed_or_unknown_red_commit_fails
    with_red_green("red_commit" => "nope") do |dir, _plane, record, _red, _green|
      assert_equal :fail, red_check(dir, record).outcome
    end
    with_red_green("red_commit" => "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef") do |dir, _plane, record, _red, _green|
      check = red_check(dir, record)
      assert_equal :fail, check.outcome
      assert_includes check.detail, "not a commit"
    end
  end

  def test_checks_without_red_commit_are_not_checked_but_a_feature_is_advised
    with_red_green do |dir, plane, record, _red, _green|
      write_check!(record, plane, {})
      check = red_check(dir, record)
      assert_equal :skip, check.outcome
      notices = SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "verification" }
      assert_equal 1, notices.size, notices.inspect
      assert_includes notices.first.message, "no check in 06-verification/tests.yml records a red_commit"
    end
  end

  def test_red_evidence_present_or_a_docs_change_is_not_advised
    with_red_green do |dir, _plane, record, _red, _green|
      assert_empty SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "verification" }
    end
    with_red_green({}, type: "docs") do |dir, plane, record, _red, _green|
      write_check!(record, plane, {})
      assert_empty SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "verification" }
    end
  end

  def test_a_pending_verification_is_not_advised
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "c1")
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: SoftFoundry::ControlPlane.new(dir))
      assert_empty SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "verification" }
    end
  end
end
