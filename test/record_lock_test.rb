# frozen_string_literal: true

require_relative "test_helper"

# The per-change lock every record update takes (THREAT-008): exclusive,
# bounded wait, never stale after a kill, never through a symlink.
class RecordLockTest < Minitest::Test
  include FoundryFixture

  def test_runs_the_block_and_returns_its_value
    Dir.mktmpdir do |dir|
      assert_equal 7, SoftFoundry::RecordLock.synchronize(dir, "c1") { 7 }
      assert File.file?(File.join(dir, ".soft-foundry", "locks", "c1.lock"))
    end
  end

  def test_is_reentrant_within_one_thread
    Dir.mktmpdir do |dir|
      value = SoftFoundry::RecordLock.synchronize(dir, "c1", timeout: 0.2) { SoftFoundry::RecordLock.synchronize(dir, "c1", timeout: 0.2) { :inner } }
      assert_equal :inner, value
    end
  end

  def test_a_holder_in_another_process_makes_the_call_fail_naming_the_lock
    Dir.mktmpdir do |dir|
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        SoftFoundry::RecordLock.synchronize(dir, "c1") do
          writer.puts "held"
          writer.flush
          sleep 30
        end
      end
      writer.close
      assert_equal "held", reader.gets.strip
      started = Time.now
      error = assert_raises(SoftFoundry::TargetError) { SoftFoundry::RecordLock.synchronize(dir, "c1", timeout: 0.3) { flunk "should not run" } }
      assert_operator Time.now - started, :<, 3
      assert_includes error.message, "c1.lock"
      assert_includes error.message, "wait for it to finish"
    ensure
      Process.kill("KILL", pid) if pid
      Process.wait(pid) if pid
    end
  end

  def test_the_lock_is_free_once_the_holder_is_killed
    Dir.mktmpdir do |dir|
      reader, writer = IO.pipe
      pid = fork do
        reader.close
        SoftFoundry::RecordLock.synchronize(dir, "c1") { writer.puts "held"; writer.flush; sleep 30 }
      end
      writer.close
      reader.gets
      Process.kill("KILL", pid)
      Process.wait(pid)
      assert_equal :ok, SoftFoundry::RecordLock.synchronize(dir, "c1", timeout: 1) { :ok }
    end
  end

  def test_refuses_a_symlinked_lock_path
    Dir.mktmpdir do |dir|
      locks = File.join(dir, ".soft-foundry", "locks")
      FileUtils.mkdir_p(locks)
      target = File.join(dir, "elsewhere")
      File.write(target, "")
      File.symlink(target, File.join(locks, "c1.lock"))
      assert_raises(SoftFoundry::TargetError) { SoftFoundry::RecordLock.synchronize(dir, "c1") { flunk "should not run" } }
    end
  end

  def test_a_slug_with_a_slash_gets_a_lock_inside_the_locks_directory
    Dir.mktmpdir do |dir|
      SoftFoundry::RecordLock.synchronize(dir, "team/c1") { nil }
      assert_equal 1, Dir.children(File.join(dir, ".soft-foundry", "locks")).size
    end
  end
end
