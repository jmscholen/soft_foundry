# frozen_string_literal: true

require_relative "test_helper"

class ControlPlaneTest < Minitest::Test
  include FoundryFixture

  def setup
    @plane = SoftFoundry::ControlPlane.new(REPO_ROOT)
  end

  def test_lifecycle_has_sixteen_phases_in_order
    assert_equal 16, @plane.phases.size
    assert_equal "intake", @plane.phases.first.id
    assert_equal "learn", @plane.phases.last.id
    assert_equal "verify", @plane.successor(@plane.phase("implement")).id
    assert_equal "implement", @plane.predecessor(@plane.phase("verify")).id
  end

  def test_path_group_expansion_and_change_substitution
    assert_includes @plane.expand("${TESTS}"), "test/**"
    assert_equal ["changes/foo/05-implementation/**"], @plane.expand("changes/${CHANGE}/05-implementation/**", change: "foo")
    assert_raises(ArgumentError) { @plane.expand("${NOPE}") }
  end

  def test_repository_yml_overrides_path_groups
    with_fixture_repo do |dir|
      File.write(File.join(dir, ".ai", "repository.yml"), YAML.dump("version" => 1, "paths" => { "APP" => ["src/**"] }))
      plane = SoftFoundry::ControlPlane.new(dir)
      assert_equal ["src/**"], plane.path_groups["APP"]
      assert_includes plane.path_groups["TESTS"], "spec/**"
    end
  end

  def test_glob_matching
    assert SoftFoundry::ControlPlane.match?("lib/a/b.rb", "lib/**")
    assert SoftFoundry::ControlPlane.match?("anything/at/all", "**")
    refute SoftFoundry::ControlPlane.match?("library/x.rb", "lib/**")
    assert SoftFoundry::ControlPlane.match?(".ai/policies/x.yml", ".ai/policies/**")
  end

  def test_evidence_bound_skills
    assert @plane.skill("verification").commit_bound?
    refute @plane.skill("implementation").commit_bound?
  end

  def test_implementation_may_write_tests_but_not_control_plane
    plane = @plane
    writes = plane.skill("implementation").permissions["write"].flat_map { |p| plane.expand(p, change: "c") }
    denies = plane.skill("implementation").permissions["deny_write"].flat_map { |p| plane.expand(p, change: "c") }
    assert SoftFoundry::ControlPlane.match_any?("test/foo_test.rb", writes)
    assert SoftFoundry::ControlPlane.match_any?(".ai/rules/general.md", denies)
    assert SoftFoundry::ControlPlane.match_any?("changes/c/06-verification/results.md", denies)
  end

  def test_every_skill_can_read_the_control_plane
    @plane.phases.each do |phase|
      reads = @plane.skill(phase.skill).permissions["read"].flat_map { |p| @plane.expand(p, change: "c") }
      assert SoftFoundry::ControlPlane.match_any?(".ai/policies/human-boundaries.yml", reads), "#{phase.skill} cannot read policies"
    end
  end
end
