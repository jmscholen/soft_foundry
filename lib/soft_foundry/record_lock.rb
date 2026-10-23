# frozen_string_literal: true

require "fileutils"
require_relative "errors"
require_relative "safe_write"

module SoftFoundry
  # The exclusive lock every update to a change record takes, so two
  # `phase run` processes (or the threads of one parallel run) cannot
  # interleave a read-modify-write of metadata.yml or a handoff. It is a
  # `flock` on `.soft-foundry/locks/<slug>.lock`: the kernel releases it
  # when the holder dies, so a killed run never leaves a stale lock.
  module RecordLock
    POLL = 0.05
    DEFAULT_TIMEOUT = 10
    DIRECTORY = File.join(".soft-foundry", "locks")

    module_function

    def path(root, slug)
      File.join(File.expand_path(root), DIRECTORY, "#{slug.to_s.gsub('/', '%2F')}.lock")
    end

    # Runs the block holding the lock. Reentrant within one thread. Waits
    # at most `timeout` seconds, then raises a TargetError naming the lock.
    def synchronize(root, slug, timeout: DEFAULT_TIMEOUT)
      lock_path = path(root, slug)
      held = (Thread.current[:soft_foundry_record_locks] ||= {})
      return yield if held[lock_path]

      file = open_lock(lock_path)
      begin
        acquire(file, lock_path, timeout)
        held[lock_path] = true
        yield
      ensure
        held.delete(lock_path)
        file.close
      end
    end

    def open_lock(lock_path)
      SafeWrite.ensure_directory!(File.dirname(File.dirname(lock_path)))
      SafeWrite.ensure_directory!(File.dirname(lock_path))
      SafeWrite.refuse_symlink!(lock_path)
      file = File.open(lock_path, File::RDWR | File::CREAT | File::NOFOLLOW, 0o600)
      unless file.stat.file?
        file.close
        raise TargetError, "#{lock_path} is not a regular file; refusing to use it as a lock"
      end
      file
    rescue Errno::ELOOP, Errno::EMLINK => e
      raise TargetError, "refusing to use #{lock_path} as a lock: #{e.class.name.split('::').last}"
    end

    def acquire(file, lock_path, timeout)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      until file.flock(File::LOCK_EX | File::LOCK_NB)
        if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          raise TargetError, "could not lock #{lock_path} within #{timeout} seconds: another soft-foundry command holds it; wait for it to finish and rerun"
        end
        sleep POLL
      end
    end
  end
end
