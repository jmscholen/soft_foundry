# frozen_string_literal: true

require_relative "test_helper"

# Go-live advisories are informational: they name what a person should
# address before a change ships and never change a gate's outcome.
class AdvisoryTest < Minitest::Test
  include FoundryFixture

  def with_record
    with_fixture_repo do |dir|
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c1", control_plane: plane)
      yield dir, plane, record
    end
  end

  def set_metadata(record)
    data = record.metadata
    yield data
    File.write(File.join(record.dir, "metadata.yml"), YAML.dump(data))
  end

  def declare_surface(record, value = true) = set_metadata(record) { |m| m["surfaces"]["accessibility"] = value }
  def skip_phase(record, id, why = "scope") = set_metadata(record) { |m| (m["skipped_phases"] ||= []) << { "phase" => id, "rationale" => why } }
  def notices(record) = SoftFoundry::Advisory.new(record).notices
  def areas(record) = notices(record).map(&:area)

  # Marks a phase as executed by `soft-foundry phase run` in a fresh
  # session, the way the runner stamps it, so the accessibility tests
  # below see only the notices they are about.
  def fresh_context!(record, phase_id)
    phase = record.control_plane.phase(phase_id)
    h = record.handoff(phase)
    h["executed_by"] = { "runner" => "soft-foundry phase run", "shell" => "claude", "fresh_context" => true }
    File.write(record.handoff_path(phase), YAML.dump(h))
  end

  def test_a_plain_change_in_a_non_ui_repository_has_no_advisories
    with_record { |_dir, _plane, record| assert_empty notices(record) }
  end

  def test_skipping_review_and_judgment_is_advised_with_the_rationale
    with_record do |_dir, _plane, record|
      skip_phase(record, "review", "the PR is the review point")
      skip_phase(record, "judge", "maintainer merge is the judgment")
      n = notices(record)
      assert_equal %w[review judgment], n.map(&:area)
      assert_includes n[0].message, "the PR is the review point"
      assert_includes n[1].message, "maintainer merge is the judgment"
    end
  end

  def test_a_skip_with_an_empty_rationale_is_not_a_skip
    with_record do |_dir, _plane, record|
      skip_phase(record, "review", "  ")
      assert_empty notices(record)
    end
  end

  def test_declared_surface_with_pending_review_is_advised
    with_record do |_dir, _plane, record|
      declare_surface(record)
      assert_equal ["accessibility"], areas(record)
      assert_includes notices(record).first.message, "has not run yet"
    end
  end

  def test_declared_surface_with_skipped_review_names_both_gaps
    with_record do |_dir, _plane, record|
      declare_surface(record)
      skip_phase(record, "review")
      assert_equal %w[review accessibility], areas(record)
      assert_includes notices(record).last.message, "no accessibility review exists"
    end
  end

  def test_declared_surface_with_na_conformance_is_advised
    with_record do |dir, plane, record|
      declare_surface(record)
      complete_phase!(record, "review", sha: head(dir))
      fresh_context!(record, "review")
      path = File.join(record.phase_dir(plane.phase("review")), "accessibility.md")
      File.write(path, "# Accessibility Review\n\n## Scope reviewed\nnothing\n\n## Findings\nnone\n\n## Conformance\nN/A because reasons\n")
      assert_equal ["accessibility"], areas(record)
      assert_includes notices(record).first.message, "N/A"
    end
  end

  def test_declared_surface_with_placeholders_left_is_advised
    with_record do |dir, _plane, record|
      declare_surface(record)
      complete_phase!(record, "review", sha: head(dir), fill: false)
      fresh_context!(record, "review")
      assert_includes notices(record).first.message, "TBD"
    end
  end

  def test_declared_surface_with_a_conforming_review_is_quiet
    with_record do |dir, plane, record|
      declare_surface(record)
      complete_phase!(record, "review", sha: head(dir))
      fresh_context!(record, "review")
      path = File.join(record.phase_dir(plane.phase("review")), "accessibility.md")
      File.write(path, "# Accessibility Review\n\n## Scope reviewed\nCLI output\n\n## Findings\nnone\n\n## Conformance\nconforms\n")
      assert_empty notices(record)
    end
  end

  def test_declared_surface_without_an_accessibility_requirement_is_advised
    with_record do |dir, _plane, record|
      declare_surface(record)
      complete_phase!(record, "specify", sha: head(dir)) # template requirement is category: functional
      assert(notices(record).any? { |n| n.message.include?("category: accessibility") })
    end
  end

  def test_declared_surface_with_an_accessibility_requirement_is_quiet_about_the_spec
    with_record do |dir, plane, record|
      declare_surface(record)
      complete_phase!(record, "specify", sha: head(dir))
      path = File.join(record.phase_dir(plane.phase("specify")), "requirements.yml")
      File.write(path, YAML.dump("requirements" => [{ "id" => "REQ-001", "category" => "accessibility", "statement" => "x" }]))
      refute(notices(record).any? { |n| n.message.include?("category: accessibility") })
    end
  end

  def test_declared_surface_with_skipped_specification_is_advised
    with_record do |_dir, _plane, record|
      declare_surface(record)
      skip_phase(record, "specify")
      assert(notices(record).any? { |n| n.message.include?("specification phase was skipped") })
    end
  end

  def test_declared_surface_with_na_evaluation_observations_is_advised
    with_record do |dir, plane, record|
      declare_surface(record)
      complete_phase!(record, "evaluate", sha: head(dir))
      path = File.join(record.phase_dir(plane.phase("evaluate")), "results.md")
      File.write(path, "# Evaluation Results\n\n## Journey outcomes\nok\n\n## Accessibility observations\nN/A\n")
      assert(notices(record).any? { |n| n.message.include?("no accessibility observations") })
      File.write(path, "# Evaluation Results\n\n## Journey outcomes\nok\n\n## Accessibility observations\nKeyboard-only: every control reachable.\n")
      refute(notices(record).any? { |n| n.message.include?("no accessibility observations") })
    end
  end

  def test_missing_standard_is_advised
    with_record do |dir, _plane, record|
      File.delete(File.join(dir, ".ai/rules/accessibility.md"))
      assert(notices(record).any? { |n| n.message.include?(".ai/rules/accessibility.md is missing") })
    end
  end

  def test_undeclared_surface_in_a_ui_repository_is_advised
    with_record do |dir, _plane, record|
      File.write(File.join(dir, ".ai/repository.yml"), YAML.dump("version" => 1, "technology" => { "frameworks" => %w[rails] }))
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: SoftFoundry::ControlPlane.new(dir))
      n = notices(record)
      assert_equal ["accessibility"], n.map(&:area)
      assert_includes n.first.message, "rails"
      assert_includes n.first.message, "surfaces.accessibility: false"
    end
  end
end

class AdvisoryCLITest < Minitest::Test
  include FoundryFixture

  def with_change(slug = "c1")
    with_fixture_repo do |dir|
      sh(dir, "git", "checkout", "-qb", "change/#{slug}")
      cli(dir, "change", "new", slug, "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, slug, control_plane: SoftFoundry::ControlPlane.new(dir))
      yield dir, record
    end
  end

  def skip_review(record)
    data = record.metadata
    data["skipped_phases"] = [{ "phase" => "review", "rationale" => "the PR is the review point" }]
    File.write(File.join(record.dir, "metadata.yml"), YAML.dump(data))
  end

  def test_gate_prints_the_advisory_block_and_still_exits_zero
    with_change do |dir, record|
      skip_review(record)
      code, out = cli(dir, "gate", "all", "--change", "c1")
      assert_equal 0, code
      assert_match(/^advisory: 1 issue to address before c1 goes live \(informational, does not block the gate\)$/, out)
      assert_match(/^  ! warn review: independent review was skipped \(the PR is the review point\)/, out)
    end
  end

  def test_change_status_and_ci_print_advisories
    with_change do |dir, record|
      skip_review(record)
      commit_all(dir, "record")
      _code, status_out = cli(dir, "change", "status", "c1")
      assert_includes status_out, "advisory: 1 issue"
      code, ci_out = cli(dir, "ci")
      assert_equal 0, code
      assert_includes ci_out, "! warn review:"
      assert_includes ci_out, "✓ ci passed"
    end
  end

  def test_change_close_prints_advisories_one_last_time_and_still_closes
    with_change do |dir, record|
      skip_review(record)
      code, out = cli(dir, "change", "close", "c1", "--force")
      assert_equal 0, code
      assert_includes out, "advisory: 1 issue to address before c1 goes live"
      assert_includes out, "c1: closed"
      assert_equal "closed", record.metadata["status"]
    end
  end

  def test_change_new_declares_the_accessibility_surface_in_a_ui_repository
    with_fixture_repo do |dir|
      File.write(File.join(dir, ".ai/repository.yml"), YAML.dump("version" => 1, "technology" => { "frameworks" => %w[react express] }))
      code, out = cli(dir, "change", "new", "ui-change", "--title", "x")
      assert_equal 0, code, out
      record = SoftFoundry::ChangeRecord.new(dir, "ui-change", control_plane: SoftFoundry::ControlPlane.new(dir))
      assert_equal true, record.metadata.dig("surfaces", "accessibility")
      body = File.read(File.join(record.dir, "metadata.yml"))
      assert_includes body, "set by change new: user-facing framework detected (express, react)"
      assert_includes body, "# Phases the harness would otherwise require", "the template's other comments survive the edit"
      # With the surface declared and nothing done yet, the advisory says what is owed.
      _code, out = cli(dir, "gate", "all", "--change", "ui-change")
      assert_includes out, "! warn accessibility: the accessibility review (13-review/accessibility.md) has not run yet"
    end
  end

  def test_change_new_leaves_the_flag_alone_in_a_non_ui_repository
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "lib-change", "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, "lib-change", control_plane: SoftFoundry::ControlPlane.new(dir))
      assert_equal false, record.metadata.dig("surfaces", "accessibility")
    end
  end
end

# The governed application's published privacy policy, security policy, and
# terms are promises a change can break (.ai/rules/policy-conformance.md).
# Like accessibility, every finding is a go-live advisory, never a gate.
class PolicyAdvisoryTest < Minitest::Test
  include FoundryFixture

  PRIVACY_ONLY = { "privacy" => { "status" => "PASS", "evidence" => ["PRIVACY.md"] } }.freeze

  # A record in a repository whose profile records the given policies:
  # block. The fixture's own profile (a copy of this repo's) records no
  # document as PASS, so a fresh change there declares no policy surface.
  def with_record(policies: nil)
    with_fixture_repo do |dir|
      File.write(File.join(dir, ".ai/repository.yml"), YAML.dump("version" => 1, "policies" => policies)) if policies
      plane = SoftFoundry::ControlPlane.new(dir)
      record = SoftFoundry::ChangeRecord.create(dir, "c1", control_plane: plane)
      yield dir, plane, record
    end
  end

  def set_metadata(record)
    data = record.metadata
    yield data
    File.write(File.join(record.dir, "metadata.yml"), YAML.dump(data))
  end

  def declare_surface(record, value = true) = set_metadata(record) { |m| m["surfaces"]["policy"] = value }
  def skip_phase(record, id, why = "scope") = set_metadata(record) { |m| (m["skipped_phases"] ||= []) << { "phase" => id, "rationale" => why } }
  def policy_notices(record) = SoftFoundry::Advisory.new(record).notices.select { |n| n.area == "policy" }
  def messages(record) = policy_notices(record).map(&:message)

  def write_review(record, plane, owed: "None.", conformance: "conforms")
    complete_phase!(record, "review", sha: head(record.root))
    path = File.join(record.phase_dir(plane.phase("review")), "policy-conformance.md")
    File.write(path, "# Policy Review\n\n## Documents checked\nPRIVACY.md (2026-09-01)\n\n## Scope reviewed\nnew analytics event\n\n## Findings\nnone\n\n## Policy text changes required\n#{owed}\n\n## Conformance\n#{conformance}\n")
  end

  def test_a_fresh_change_in_a_repository_without_published_policies_is_quiet
    with_record { |_dir, _plane, record| assert_empty policy_notices(record) }
  end

  def test_change_new_declares_the_surface_when_the_profile_records_a_published_policy
    with_record(policies: PRIVACY_ONLY) do |_dir, _plane, record|
      assert_equal true, record.metadata.dig("surfaces", "policy")
      body = File.read(File.join(record.dir, "metadata.yml"))
      assert_includes body, "set by change new: published policy document recorded (privacy); .ai/rules/policy-conformance.md applies"
      assert_includes body, "# Human-boundary decisions this change required", "the template's other comments survive the edit"
      assert_includes body, "  accessibility: false", "the accessibility line is untouched in a non-UI repository"
    end
  end

  def test_a_recorded_but_absent_document_does_not_declare_the_surface
    with_record(policies: { "privacy" => { "status" => "MISSING" }, "security" => { "status" => "UNKNOWN" } }) do |_dir, _plane, record|
      assert_equal false, record.metadata.dig("surfaces", "policy")
      assert_empty policy_notices(record)
    end
  end

  def test_undeclared_surface_in_a_repository_with_published_policies_is_advised
    with_record(policies: PRIVACY_ONLY) do |_dir, _plane, record|
      declare_surface(record, false)
      assert_equal 1, policy_notices(record).size
      assert_includes messages(record).first, "published policy documents (privacy)"
      assert_includes messages(record).first, "surfaces.policy: false"
    end
  end

  def test_declared_surface_with_pending_review_is_advised
    with_record(policies: PRIVACY_ONLY) do |_dir, _plane, record|
      assert_equal ["the policy-conformance review (13-review/policy-conformance.md) has not run yet"], messages(record)
    end
  end

  def test_declared_surface_with_no_document_to_check_against_is_advised
    with_record do |_dir, _plane, record|
      declare_surface(record)
      assert(messages(record).any? { |m| m.include?("records no published privacy, security, or terms document") })
      assert(messages(record).any? { |m| m.include?("has not run yet") })
    end
  end

  def test_declared_surface_with_skipped_review_names_the_gap
    with_record(policies: PRIVACY_ONLY) do |_dir, _plane, record|
      skip_phase(record, "review")
      assert_includes messages(record).first, "no policy-conformance review exists"
    end
  end

  def test_declared_surface_without_a_policy_requirement_is_advised
    with_record(policies: PRIVACY_ONLY) do |dir, plane, record|
      complete_phase!(record, "specify", sha: head(dir)) # template requirement is category: functional
      assert(messages(record).any? { |m| m.include?("category: policy") })
      path = File.join(record.phase_dir(plane.phase("specify")), "requirements.yml")
      File.write(path, YAML.dump("requirements" => [{ "id" => "REQ-001", "category" => "policy", "statement" => "x" }]))
      refute(messages(record).any? { |m| m.include?("category: policy") })
    end
  end

  def test_declared_surface_with_skipped_specification_is_advised
    with_record(policies: PRIVACY_ONLY) do |_dir, _plane, record|
      skip_phase(record, "specify")
      assert(messages(record).any? { |m| m.include?("no policy requirements were recorded") })
    end
  end

  def test_review_with_placeholders_or_na_is_advised_and_a_conforming_one_is_quiet
    with_record(policies: PRIVACY_ONLY) do |dir, plane, record|
      complete_phase!(record, "review", sha: head(dir), fill: false)
      assert_includes messages(record).first, "TBD"
      write_review(record, plane, conformance: "N/A because reasons")
      assert_includes messages(record).first, "declares conformance N/A"
      write_review(record, plane)
      assert_empty policy_notices(record)
    end
  end

  def test_policy_text_changes_owed_are_a_legal_commitment_until_a_person_decides
    with_record(policies: PRIVACY_ONLY) do |_dir, plane, record|
      write_review(record, plane, owed: "- Clause 4: add the analytics vendor as a recipient.")
      assert_equal 1, policy_notices(record).size
      assert_includes messages(record).first, "legal commitment"
      assert_includes messages(record).first, "status: awaiting_human"

      set_metadata(record) { |m| m["status"] = "awaiting_human" }
      assert_includes messages(record).first, "parked awaiting a person's decision"

      set_metadata(record) { |m| m["human_decisions"] = [{ "boundary" => "legal commitment", "subject" => "clause 4", "decided_by" => "TBD" }] }
      assert_includes messages(record).first, "parked", "a placeholder decision is not a decision"

      set_metadata(record) { |m| m["human_decisions"] = [{ "boundary" => "legal commitment", "subject" => "clause 4", "decided_by" => "a person", "decided_at" => "2026-09-15", "decision" => "approved" }] }
      assert_empty policy_notices(record)
    end
  end

  def test_missing_standard_is_advised
    with_record do |dir, _plane, record|
      File.delete(File.join(dir, ".ai/rules/policy-conformance.md"))
      assert(messages(record).any? { |m| m.include?(".ai/rules/policy-conformance.md is missing") })
    end
  end

  def test_gate_prints_policy_advisories_and_still_exits_zero
    with_record(policies: PRIVACY_ONLY) do |dir, _plane, _record|
      code, out = cli(dir, "gate", "all", "--change", "c1")
      assert_equal 0, code
      assert_match(/^advisory: 1 issue to address before c1 goes live/, out)
      assert_match(/^  ! warn policy: the policy-conformance review/, out)
    end
  end
end

# Every outcome soft-foundry prints carries a word, so the meaning survives
# a terminal or screen reader that cannot render the glyph next to it
# (.ai/rules/accessibility.md, command-line rules).
class StatusWordTest < Minitest::Test
  include FoundryFixture

  def ascii(text) = text.gsub(/[^ -~\n]/, "")

  def test_doctor_lines_carry_pass_or_fail_words
    with_fixture_repo do |dir|
      _code, out = cli(dir, "doctor")
      lines = out.lines.map(&:chomp)
      assert(lines.all? { |l| l.match?(/\A(✓ pass|✗ fail) \S/) }, out)
      assert_match(/^ pass git repository$/, ascii(out))
      assert_match(/^ fail \.ai\/manifest\.yml$/, ascii(out))
    end
  end

  def test_check_summary_and_findings_carry_words
    with_fixture_repo do |dir|
      _code, out = cli(dir, "check")
      assert_match(/^✓ pass control plane: /, out)
      File.delete(File.join(dir, ".ai/rules/accessibility.md"))
      _code, out = cli(dir, "check")
      assert_match(/^! warning \.ai\/rules\/accessibility\.md is missing/, out)
      File.delete(File.join(dir, ".ai/rules/policy-conformance.md"))
      code, out = cli(dir, "check")
      assert_equal 0, code, "standards missing are warnings, not errors"
      assert_match(/^! warning \.ai\/rules\/policy-conformance\.md is missing/, out)
      File.delete(File.join(dir, ".ai/skills/planning/template/rollback.md"))
      code, out = cli(dir, "check")
      assert_equal 2, code
      assert_match(/^✗ error skill planning/, out)
      assert_match(/^✗ fail control plane: 1 error/, out)
    end
  end

  def test_gate_check_lines_carry_words_for_every_outcome
    with_fixture_repo do |dir|
      cli(dir, "change", "new", "c1", "--title", "x")
      record = SoftFoundry::ChangeRecord.new(dir, "c1", control_plane: SoftFoundry::ControlPlane.new(dir))
      complete_phase!(record, "intake", sha: head(dir))
      complete_phase!(record, "discover", sha: head(dir), fill: false)
      _code, out = cli(dir, "gate", "all", "--change", "c1")
      assert_match(/^  ✓ pass handoff identity$/, out)
      assert_match(/^  ✗ fail no placeholders: TBD remains in/, out)
      assert_match(/^  - skip phase pending: not started$/, out)
      stripped = ascii(out)
      assert_match(/^   pass handoff identity$/, stripped)
      assert_match(/^   fail no placeholders/, stripped)
    end
  end
end
