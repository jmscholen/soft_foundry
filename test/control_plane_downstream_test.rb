# frozen_string_literal: true

require_relative "test_helper"

class ControlPlaneDownstreamTest < Minitest::Test
  include FoundryFixture

  def plane = SoftFoundry::ControlPlane.new(FoundryFixture::REPO_ROOT)

  def ids(phase_id) = plane.downstream(plane.phase(phase_id)).map(&:id)

  def test_downstream_is_every_later_lifecycle_phase_in_order_excluding_the_phase
    assert_equal %w[evaluate attack remediate document index observe review judge learn], ids("verify")
    assert_equal %w[learn], ids("judge")
    assert_equal [], ids("learn")
  end

  def test_remediate_follows_its_next_transition_back_to_verify
    assert_equal %w[verify evaluate attack document index observe review judge learn], ids("remediate")
  end

  def test_a_phase_reached_only_by_lifecycle_order_does_not_follow_the_loop_back
    refute_includes ids("evaluate"), "verify"
    refute_includes ids("attack"), "verify"
    refute_includes ids("judge"), "intake"
  end

  def test_the_result_is_in_lifecycle_order_without_the_phase_or_duplicates
    plane.phases.each do |p|
      down = plane.downstream(p)
      refute_includes down, p
      assert_equal down.uniq, down
      assert_equal down.sort_by { |d| plane.phases.index(d) }, down
    end
  end

  def test_isolated_phases_reads_the_workflow_and_drops_unknown_ids
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(FoundryFixture::REPO_ROOT, ".ai"), dir)
      workflow = File.join(dir, ".ai", "workflow.yml")
      File.write(workflow, File.read(workflow).gsub(/^isolated_phases:.*\n/, "") + "\nisolated_phases: [evaluate, attack, nonsense]\n")
      assert_equal %w[evaluate attack], SoftFoundry::ControlPlane.new(dir).isolated_phases.map(&:id)
    end
  end

  def test_an_absent_isolated_phases_key_gives_an_empty_list
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(FoundryFixture::REPO_ROOT, ".ai"), dir)
      workflow = File.join(dir, ".ai", "workflow.yml")
      File.write(workflow, File.read(workflow).gsub(/^isolated_phases:.*\n/, ""))
      assert_equal [], SoftFoundry::ControlPlane.new(dir).isolated_phases
    end
  end
end
