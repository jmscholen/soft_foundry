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

  def test_last_commit_sha_is_the_most_recently_completed_phase
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c1", control_plane: plane)
      assert_nil record.last_commit_sha
      complete_phase!(record, "intake", sha: "1111111")
      assert_equal "1111111", record.last_commit_sha
      complete_phase!(record, "discover", sha: "2222222")
      assert_equal "2222222", record.last_commit_sha, "the later phase's sha wins"
    end
  end

  def test_undischarged_acceptance_reads_the_judgment_evidence_file
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c2", control_plane: plane)
      assert_empty record.undischarged_acceptance

      data = YAML.safe_load_file(record.judgment_evidence_path)
      data["undischarged"] = [{"id" => "AC-060", "description" => "observed on production"}]
      File.write(record.judgment_evidence_path, YAML.dump(data))

      assert_equal [{"id" => "AC-060", "description" => "observed on production"}], record.undischarged_acceptance
    end
  end

  def test_discharge_moves_items_and_records_the_confirmation_source
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c3", control_plane: plane)
      item = {"id" => "AC-060", "description" => "observed on production"}
      data = YAML.safe_load_file(record.judgment_evidence_path)
      data["undischarged"] = [item]
      File.write(record.judgment_evidence_path, YAML.dump(data))

      record.discharge!([item], confirmed_by: "PR #5 comment")

      assert_empty record.undischarged_acceptance
      discharged = record.judgment_evidence["discharged"]
      assert_equal 1, discharged.size
      assert_equal "AC-060", discharged.first["id"]
      assert_equal "PR #5 comment", discharged.first["discharged_by"]
    end
  end

  def test_close_flips_status_and_current_phase
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c4", control_plane: plane)
      record.close!
      assert_equal "closed", record.metadata["status"]
      assert_equal "done", record.metadata["current_phase"]
    end
  end
end
