# frozen_string_literal: true

require "yaml"
require "date"
require_relative "errors"
require_relative "text"

module SoftFoundry
  # A record file that cannot be read as the record's own: a symlink, a
  # non-regular file, or an unreadable one. The target repository is at
  # fault, so commands exit 1 with the message.
  class RecordFileError < TargetError; end

  # Reads files under changes/<slug>/ that the gate, the sealing command,
  # and the summary trust by path. A symlink at any of them would let the
  # content of another file stand in for the record's, so it is refused
  # before anything is read (REQ-034).
  module RecordFile
    module_function

    def check!(path, label = path)
      raise RecordFileError, "#{label} is a symlink; a record file must be a regular file (replace the link with the file itself)" if File.symlink?(path)
      raise RecordFileError, "#{label} is missing" unless File.exist?(path)
      raise RecordFileError, "#{label} is not a regular file" unless File.file?(path)
      path
    end

    def read(path, label = path) = SoftFoundry.read_text(check!(path, label))

    # The file as YAML, with the classes record files carry and aliases
    # allowed. An empty file is an empty mapping. Parse errors propagate as
    # Psych exceptions so the caller can name the line.
    def load_yaml(path, label = path)
      data = YAML.safe_load(read(path, label), permitted_classes: [Time, Date], aliases: true, filename: label)
      data.nil? ? {} : data
    end
  end
end
