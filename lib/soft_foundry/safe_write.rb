# frozen_string_literal: true

require "fileutils"
require_relative "errors"

module SoftFoundry
  # Filesystem writes that never follow symlinks and never write through a
  # planted temporary sibling. Every write goes to `<path>.soft-foundry-tmp`
  # opened with O_EXCL|O_NOFOLLOW, then renames over the destination.
  module SafeWrite
    TMP_SUFFIX = ".soft-foundry-tmp"

    module_function

    def write(path, bytes)
      refuse_non_regular!(File.dirname(path), directory: true)
      refuse_symlink!(path)
      tmp = path + TMP_SUFFIX
      raise TargetError, "#{tmp} already exists (planted or leftover temporary file); remove it and rerun" if File.symlink?(tmp) || File.exist?(tmp)
      File.open(tmp, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o644) { |f| f.write(bytes) }
      refuse_symlink!(path)
      File.rename(tmp, path)
    rescue Errno::EEXIST, Errno::ELOOP => e
      raise TargetError, "refusing to write #{path}: #{e.class.name.split('::').last} (#{e.message})"
    ensure
      File.unlink(tmp) if tmp && File.symlink?(tmp) == false && File.exist?(tmp) && !File.exist?(path)
    end

    # The directory must be a real directory (or absent, in which case it is created).
    def ensure_directory!(dir)
      raise TargetError, "#{dir} is a symlink; refusing to use it" if File.symlink?(dir)
      raise TargetError, "#{dir} exists but is not a directory" if File.exist?(dir) && !File.directory?(dir)
      FileUtils.mkdir_p(dir)
      raise TargetError, "#{dir} is not writable" unless File.writable?(dir)
    end

    def refuse_symlink!(path)
      raise TargetError, "#{path} is a symlink; refusing to write through it" if File.symlink?(path)
      raise TargetError, "#{path} exists but is not a regular file" if File.exist?(path) && !File.file?(path)
    end

    def refuse_non_regular!(path, directory: false)
      raise TargetError, "#{path} is a symlink; refusing to write through it" if File.symlink?(path)
      return unless File.exist?(path)
      raise TargetError, "#{path} is not a directory" if directory && !File.directory?(path)
    end
  end
end
