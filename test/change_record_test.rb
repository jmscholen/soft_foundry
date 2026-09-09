# frozen_string_literal: true

require_relative "test_helper"

class ChangeRecordTest < Minitest::Test
  include FoundryFixture

  def test_create_scaffolds_every_phase_from_templates
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "add-widget", control_plane: plane, title: "Add widget", branch: "change/add-widget")
      plane.phases.each do |phase|
        skill = plane.skill(phase.skill)
        skill.required_files.each do |f|
          assert File.exist?(File.join(record.phase_dir(phase), f)), "#{phase.output}/#{f} missing"
        end
      end
      handoff = record.handoff(plane.phase("remediate"))
      assert_equal "09-remediation", handoff["phase"]
      assert_equal "remediation", handoff["skill"]
      assert_equal "coding_high", handoff.dig("resolved_model", "profile")
      assert_equal "verify", handoff["next"], "remediation must loop to verify"
      assert_equal "done", record.handoff(plane.phase("learn"))["next"]
      assert_equal "Add widget", record.metadata.dig("change", "title")
      assert_equal "change/add-widget", record.metadata.dig("git", "branch")
      assert_equal "intake", record.metadata["current_phase"]
    end
  end

  def test_create_refuses_duplicates_and_bad_slugs
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      SoftFoundry::ChangeRecord.create(dir, "x", control_plane: plane)
      assert_raises(RuntimeError) { SoftFoundry::ChangeRecord.create(dir, "x", control_plane: plane) }
      assert_raises(ArgumentError) { SoftFoundry::ChangeRecord.new(dir, "../escape", control_plane: plane) }
    end
  end
end
