# frozen_string_literal: true

require_relative "test_helper"

class MaturityReportTest < Minitest::Test
  def unassessed
    SoftFoundry::MaturityReport.new({})
  end

  def sample
    SoftFoundry::MaturityReport.new(
      "repository" => {"assessed" => true, "assessed_at" => "2026-01-01T00:00:00Z", "assessed_by" => "test", "commit_sha" => "abc123"},
      "maturity" => {"current_level" => 4, "current_id" => "verified", "gaps" => [
        {"level" => 5, "capability" => "observability.alerting", "status" => "PARTIAL"}
      ]},
      "capabilities" => {
        "observability.alerting" => {"status" => "PARTIAL", "findings" => ["no_pager"], "evidence" => ["config/x.yml"], "rationale" => "Dashboard only, no pager."},
        "observability.latency_signal" => {"status" => "UNKNOWN", "rationale" => "No tracing found."},
        "repository.git_detected" => {"status" => "PASS"}
      }
    )
  end

  def test_unassessed_summary_and_markdown_say_so_plainly
    r = unassessed
    assert_includes r.summary_lines.join("\n"), "not yet assessed"
    assert_includes r.to_markdown, "not been assessed"
  end

  def test_gaps_are_distinguished_from_other_deficiencies
    r = sample
    assert_equal ["observability.alerting"], r.gaps.map { |g| g["capability"] }
    assert_equal ["observability.latency_signal"], r.other_deficiencies.keys
  end

  def test_satisfied_count_excludes_non_satisfied_statuses
    assert_equal 1, sample.satisfied_count
  end

  def test_summary_lines_include_level_gaps_and_report_pointer
    lines = sample.summary_lines.join("\n")
    assert_includes lines, "level 4 (verified)"
    assert_includes lines, "observability.alerting (PARTIAL)"
    assert_includes lines, "1 other recorded deficiency"
    assert_includes lines, ".ai/maturity-report.md"
  end

  def test_markdown_includes_rationale_findings_and_evidence_for_gaps
    md = sample.to_markdown
    assert_includes md, "Dashboard only, no pager."
    assert_includes md, "no_pager"
    assert_includes md, "config/x.yml"
    assert_includes md, "## Blocking the next level"
    assert_includes md, "## Other recorded deficiencies"
    assert_includes md, "observability.latency_signal"
  end

  def test_no_gaps_says_so_and_omits_the_section_body
    r = SoftFoundry::MaturityReport.new(
      "repository" => {"assessed" => true},
      "maturity" => {"current_level" => 7, "current_id" => "self_improving", "gaps" => []},
      "capabilities" => {"repository.git_detected" => {"status" => "PASS"}}
    )
    assert_includes r.summary_lines.join("\n"), "nothing currently blocks the next level"
    assert_includes r.to_markdown, "Nothing currently blocks the next level."
  end

  def test_no_other_deficiencies_omits_that_section
    r = SoftFoundry::MaturityReport.new(
      "repository" => {"assessed" => true},
      "maturity" => {"current_level" => 1, "current_id" => "agent_accessible", "gaps" => [{"level" => 2, "capability" => "x", "status" => "MISSING"}]},
      "capabilities" => {"x" => {"status" => "MISSING"}}
    )
    refute_includes r.to_markdown, "Other recorded deficiencies"
    refute_includes r.summary_lines.join("\n"), "other recorded"
  end

  def test_from_file_loads_yaml
    Dir.mktmpdir do |dir|
      path = File.join(dir, "repository.yml")
      File.write(path, YAML.dump("repository" => {"assessed" => true}, "maturity" => {"current_level" => 2, "current_id" => "contextualized", "gaps" => []}, "capabilities" => {}))
      r = SoftFoundry::MaturityReport.from_file(path)
      assert_equal 2, r.current_level
    end
  end
end
