# frozen_string_literal: true

require "digest"
require "yaml"
require_relative "errors"

module SoftFoundry
  # `.ai/manifest.yml`: the SHA-256 of every control-plane file Soft Foundry
  # installed. It is the only basis for deciding that a file is Soft
  # Foundry-owned rather than user-modified.
  class Manifest
    PATH = ".ai/manifest.yml"
    VERSION = 1
    HEX = /\A[0-9a-f]{64}\z/

    attr_reader :files, :soft_foundry_version

    def self.digest(bytes) = Digest::SHA256.hexdigest(bytes)

    def self.load(root)
      path = File.join(root, PATH)
      return new unless File.exist?(path) || File.symlink?(path)
      raise TargetError, "#{PATH} is a symlink; refusing to read it" if File.symlink?(path)
      raise TargetError, "#{PATH} is not a regular file; refusing to read it" unless File.file?(path)

      data = YAML.safe_load(File.binread(path), aliases: false)
      validate!(data)
      new(files: data["files"], soft_foundry_version: data["soft_foundry_version"])
    rescue Psych::Exception => e
      raise TargetError, "#{PATH} is not valid YAML: #{e.message}"
    end

    def self.validate!(data)
      raise TargetError, "#{PATH} invalid: expected a mapping" unless data.is_a?(Hash)
      raise TargetError, "#{PATH} invalid: version must be #{VERSION}" unless data["version"] == VERSION
      files = data["files"]
      raise TargetError, "#{PATH} invalid: files must be a mapping" unless files.is_a?(Hash)
      files.each do |path, sha|
        bad = !path.is_a?(String) || path.start_with?("/") || path.split("/").include?("..") || !path.start_with?(".ai/")
        raise TargetError, "#{PATH} invalid: entry '#{path}' is not a relative path under .ai/" if bad
        raise TargetError, "#{PATH} invalid: entry '#{path}' has no SHA-256 hash" unless sha.is_a?(String) && sha.match?(HEX)
      end
    end

    def initialize(files: {}, soft_foundry_version: nil)
      @files = files.dup
      @soft_foundry_version = soft_foundry_version
    end

    def add(path, bytes) = @files[path] = self.class.digest(bytes)
    def include?(path) = @files.key?(path)
    def owned?(path, bytes) = @files[path] == self.class.digest(bytes)

    def to_yaml
      YAML.dump("version" => VERSION, "soft_foundry_version" => soft_foundry_version, "files" => @files.sort.to_h)
    end
  end
end
