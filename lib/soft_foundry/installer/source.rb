# frozen_string_literal: true

require_relative "../errors"

module SoftFoundry
  class Installer
    # The canonical installable set, read from the installed gem (or any
    # directory laid out like this repository). Nothing is fetched from the
    # network. Symlinked or traversing entries indicate a tampered package.
    class Source
      Entry = Data.define(:path, :bytes)

      BEGIN_MARKER = "<!-- soft-foundry:begin -->"
      END_MARKER = "<!-- soft-foundry:end -->"
      REQUIRED = [".ai/workflow.yml", ".ai/templates/repository.yml", "AGENTS.md"].freeze
      SCAFFOLD = ["changes/README.md", "docs/user/README.md"].freeze
      EXCLUDED = [".ai/repository.yml", ".ai/manifest.yml"].freeze

      attr_reader :root

      def self.packaged = new(File.expand_path("../../..", __dir__))

      def initialize(root)
        @root = File.expand_path(root)
      end

      def entries
        @entries ||= begin
          (REQUIRED + SCAFFOLD).each do |rel|
            raise InternalError.new("packaged file missing: #{rel}", component: "package", diagnostic: ["source: #{root}"]) unless File.file?(File.join(root, rel))
          end
          list = Dir.glob(".ai/**/*", File::FNM_DOTMATCH, base: root).sort.filter_map { |rel| entry_for(rel) }
          list << Entry.new(path: ".ai/repository.yml", bytes: read(".ai/templates/repository.yml"))
          SCAFFOLD.each { |rel| list << Entry.new(path: rel, bytes: read(rel)) }
          list.sort_by(&:path)
        end
      end

      def paths = entries.map(&:path)

      # The text Soft Foundry owns inside a target's AGENTS.md.
      def agents_interior
        body = File.read(File.join(root, "AGENTS.md"))
        if body.include?(BEGIN_MARKER) && body.include?(END_MARKER)
          body[(body.index(BEGIN_MARKER) + BEGIN_MARKER.length)...body.index(END_MARKER)].strip
        else
          body.sub(/\A# [^\n]*\n/, "").strip
        end
      end

      private

      def entry_for(rel)
        return nil if %w[. ..].include?(File.basename(rel))
        abs = File.join(root, rel)
        raise InternalError.new("packaged entry is a symlink: #{rel}", component: "package") if File.symlink?(abs)
        raise InternalError.new("packaged entry traverses directories: #{rel}", component: "package") if rel.split("/").include?("..")
        return nil unless File.file?(abs)
        return nil if EXCLUDED.include?(rel)
        return nil if rel.start_with?(".ai/harness-evals/") && rel != ".ai/harness-evals/README.md"
        Entry.new(path: rel, bytes: File.binread(abs))
      end

      def read(rel) = File.binread(File.join(root, rel))
    end
  end
end
