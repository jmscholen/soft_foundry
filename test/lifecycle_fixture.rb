# frozen_string_literal: true

require_relative "test_helper"

# A gated change on its own branch with a chosen set of phases complete at
# HEAD, shared by the phase-lifecycle-controls tests.
module LifecycleFixture
  include FoundryFixture

  LIFECYCLE = %w[intake discover specify threat_model plan implement verify evaluate attack review judge].freeze
  RECORDS = "changes"

  def set_metadata!(record, status: nil, current_phase: nil)
    path = File.join(record.dir, "metadata.yml")
    text = File.read(path)
    text = text.sub(/^status: .*$/, "status: #{status}") if status
    text = text.sub(/^current_phase: .*$/, "current_phase: #{current_phase}") if current_phase
    File.write(path, text)
  end

  def with_lifecycle_record(slug = "c1", complete: LIFECYCLE, status: "in_progress", current_phase: "judge")
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      cli(dir, "change", "new", slug)
      record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: SoftFoundry::ControlPlane.new(dir))
      set_metadata!(record, status: status, current_phase: current_phase)
      commit_all(dir, "record")
      complete.each { |id| complete_phase!(record, id, sha: head(dir)) }
      commit_all(dir, "phases complete") unless complete.empty?
      yield dir, record
    end
  end

  def with_clean_env(extra = {}, &block)
    with_env({ "ANTHROPIC_API_KEY" => nil, "OPENAI_API_KEY" => nil, "XAI_API_KEY" => nil, "OPENROUTER_API_KEY" => nil,
               "SOFT_FOUNDRY_BILLING" => nil, "SOFT_FOUNDRY_PHASE" => nil, "SOFT_FOUNDRY_PARALLEL" => nil }.merge(extra), &block)
  end

  def run_cli(dir, *args, **opts)
    out = StringIO.new
    err = StringIO.new
    code = nil
    env = opts.delete(:env) || {}
    with_clean_env(env) { code = SoftFoundry::CLI.new(args, out: out, err: err, root: dir, **opts).run }
    [code, out.string, err.string]
  end

  def statuses(record)
    record.control_plane.phases.to_h { |p| [p.id, record.phase_status(p)] }
  end

  # Every file under the given directory (default: all change records)
  # mapped to its bytes.
  def tree_bytes(dir, sub = RECORDS)
    Dir.glob("#{sub}/**/*", File::FNM_DOTMATCH, base: dir).select { |f| File.file?(File.join(dir, f)) }.to_h { |f| [f, File.binread(File.join(dir, f))] }
  end
end
