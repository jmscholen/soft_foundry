# frozen_string_literal: true

require_relative "test_helper"

class TextFreeTextTest < Minitest::Test
  def free(value, max: 500) = SoftFoundry::Text.free_text!(value, "reason", max: max)

  def test_accepts_ordinary_text_and_returns_it_stripped
    assert_equal "fixture changed", free("  fixture changed ")
  end

  def test_accepts_yaml_looking_text_unchanged
    assert_equal "a: b", free("a: b")
    assert_equal "---", free("---")
  end

  def test_accepts_unicode
    assert_equal "naïve — ok", free("naïve — ok")
  end

  def test_length_limit_is_inclusive
    assert_equal "a" * 500, free("a" * 500)
    error = assert_raises(ArgumentError) { free("a" * 501) }
    assert_includes error.message, "reason"
    assert_includes error.message, "500"
  end

  def test_refuses_empty_and_blank
    assert_raises(ArgumentError) { free("") }
    assert_raises(ArgumentError) { free("   ") }
    assert_raises(ArgumentError) { free(nil) }
  end

  def test_refuses_control_characters
    ["two\nlines", "esc\e[31m", "nul\0byte", "tab\there", "cr\rx"].each do |bad|
      error = assert_raises(ArgumentError, bad.inspect) { free(bad) }
      assert_includes error.message, "control character"
    end
  end

  def test_id_and_env_name_patterns
    assert_equal "GOLIVE-1", SoftFoundry::Text.id!("GOLIVE-1")
    assert_raises(ArgumentError) { SoftFoundry::Text.id!("golive") }
    assert_raises(ArgumentError) { SoftFoundry::Text.id!("-X") }
    assert_equal "DATABASE_URL", SoftFoundry::Text.env_name!("DATABASE_URL")
    assert_raises(ArgumentError) { SoftFoundry::Text.env_name!("1X") }
    assert_raises(ArgumentError) { SoftFoundry::Text.env_name!("SOFT_FOUNDRY_PHASE") }
    assert_raises(ArgumentError) { SoftFoundry::Text.env_name!("lower") }
  end
end
