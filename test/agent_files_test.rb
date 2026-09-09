# frozen_string_literal: true

require_relative "test_helper"

class AgentFilesTest < Minitest::Test
  include FoundryFixture

  def files(dir) = SoftFoundry::AgentFiles.new(dir, agents_interior: "1. Read `.ai/README.md`.")

  def test_created_then_skipped
    Dir.mktmpdir do |dir|
      plan = files(dir).plan_agents
      assert_equal "created", plan.status
      File.write(File.join(dir, "AGENTS.md"), plan.bytes)
      assert_equal "skipped", files(dir).plan_agents.status
    end
  end

  def test_existing_text_preserved_and_block_appended_once
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "AGENTS.md"), "# Ours\nProject rules here")
      plan = files(dir).plan_agents
      assert_equal "updated", plan.status
      assert plan.bytes.start_with?("# Ours\nProject rules here\n")
      assert_equal 1, plan.bytes.scan(SoftFoundry::AgentFiles::BEGIN_MARKER).size
      File.write(File.join(dir, "AGENTS.md"), plan.bytes)
      assert_equal "skipped", files(dir).plan_agents.status
    end
  end

  def test_bare_marker_is_conflict
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "CLAUDE.md"), "# x\n#{SoftFoundry::AgentFiles::BEGIN_MARKER}\n")
      assert_equal "conflict", files(dir).plan_claude.status
      File.write(File.join(dir, "CLAUDE.md"), "# x\n#{SoftFoundry::AgentFiles::LEGACY_CLAUDE_MARKER}\n")
      assert_equal "conflict", files(dir).plan_claude.status
    end
  end

  def test_legacy_claude_block_is_recognized
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "CLAUDE.md"), "# Claude Code Instructions\n#{SoftFoundry::AgentFiles::LEGACY_CLAUDE_BLOCK}")
      assert_equal "skipped", files(dir).plan_claude.status
    end
  end

  def test_symlinked_pointer_file_is_refused
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "real.md"), "x")
      File.symlink(File.join(dir, "real.md"), File.join(dir, "AGENTS.md"))
      assert_raises(SoftFoundry::TargetError) { files(dir).plan_agents }
    end
  end
end
