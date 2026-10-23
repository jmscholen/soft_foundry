# frozen_string_literal: true

require_relative "test_helper"

# Record updates re-read from disk under the lock and are written
# atomically; a multi-file transaction applies entirely or not at all.
class ChangeRecordUpdateTest < Minitest::Test
  include FoundryFixture

  def with_record
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/c1")
      cli(dir, "change", "new", "c1")
      yield dir, SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: SoftFoundry::ControlPlane.new(dir))
    end
  end

  def test_update_metadata_re_reads_disk_so_another_writers_change_is_kept
    with_record do |_dir, record|
      stale = record.metadata
      path = File.join(record.dir, "metadata.yml")
      other = YAML.safe_load_file(path, permitted_classes: [Time, Date])
      other["risk"] = "low"
      File.write(path, YAML.dump(other))
      record.update_metadata { |meta| meta["current_phase"] = "plan" }
      after = record.metadata
      assert_equal "low", after["risk"]
      assert_equal "plan", after["current_phase"]
      refute_equal stale["current_phase"], after["current_phase"]
    end
  end

  def test_update_handoff_writes_the_handoff_atomically
    with_record do |_dir, record|
      phase = record.control_plane.phase("intake")
      record.update_handoff(phase) { |h| h["notes"] = "hello" }
      assert_equal "hello", record.handoff(phase)["notes"]
      refute File.exist?(record.handoff_path(phase) + SoftFoundry::SafeWrite::TMP_SUFFIX)
    end
  end

  def test_transaction_applies_every_file
    with_record do |_dir, record|
      a = record.control_plane.phase("intake")
      b = record.control_plane.phase("discover")
      record.transaction do |tx|
        tx.metadata { |m| m["current_phase"] = "discover" }
        tx.handoff(a) { |h| h["notes"] = "a" }
        tx.handoff(b) { |h| h["notes"] = "b" }
      end
      assert_equal "discover", record.metadata["current_phase"]
      assert_equal "a", record.handoff(a)["notes"]
      assert_equal "b", record.handoff(b)["notes"]
    end
  end

  def test_a_failure_while_staging_leaves_the_record_byte_identical
    with_record do |dir, record|
      a = record.control_plane.phase("intake")
      b = record.control_plane.phase("discover")
      snapshot = -> { Dir.glob("changes/c1/**/*", base: dir).select { |f| File.file?(File.join(dir, f)) }.to_h { |f| [f, File.binread(File.join(dir, f))] } }
      before = snapshot.call
      planted = record.handoff_path(b) + SoftFoundry::SafeWrite::TMP_SUFFIX
      File.write(planted, "planted")
      before[planted.delete_prefix("#{dir}/")] = "planted"
      assert_raises(SoftFoundry::TargetError) do
        record.transaction do |tx|
          tx.metadata { |m| m["current_phase"] = "discover" }
          tx.handoff(a) { |h| h["notes"] = "a" }
          tx.handoff(b) { |h| h["notes"] = "b" }
        end
      end
      assert_equal before, snapshot.call
    end
  end

  def test_released_and_finished_predicates
    with_record do |_dir, record|
      refute record.released?
      refute record.finished?
      record.update_metadata { |m| m["status"] = "released" }
      assert record.released?
      assert record.finished?
      record.update_metadata { |m| m["status"] = "closed" }
      refute record.released?
      assert record.finished?
    end
  end

  def test_release_items_and_open_release_items
    with_record do |_dir, record|
      assert_equal [], record.release_items
      record.update_metadata do |m|
        m["release"] = { "at" => "t", "commit" => "c", "items" => [{ "id" => "A", "description" => "a" },
                                                                    { "id" => "B", "description" => "b", "discharged_at" => "t" }] }
      end
      assert_equal %w[A B], record.release_items.map { |i| i["id"] }
      assert_equal %w[A], record.open_release_items.map { |i| i["id"] }
    end
  end

  def test_two_processes_updating_the_same_record_lose_nothing
    with_record do |_dir, record|
      pids = 2.times.map do |n|
        fork do
          10.times { |i| record.update_metadata { |m| (m["tally"] ||= []) << "#{n}-#{i}" } }
          exit!(0)
        end
      end
      pids.each { |pid| Process.wait(pid) }
      assert_equal 20, record.metadata["tally"].size
    end
  end
end
