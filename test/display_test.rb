# frozen_string_literal: true

require_relative "test_helper"

# The one escaper every new line that echoes recorded text goes through.
class DisplayTest < Minitest::Test
  def test_control_invisible_and_bidi_characters_become_visible_escapes
    assert_equal "a<U+001B>[31mb", SoftFoundry::Display.safe("a\e[31mb")
    assert_equal "x<U+000D>y<U+0000>z", SoftFoundry::Display.safe("x\ry\0z")
    assert_equal "p<U+202E>q<U+200B>r", SoftFoundry::Display.safe("p‮q​r")
    assert_equal "a<U+000A>b", SoftFoundry::Display.safe("a\nb")
  end

  def test_plain_text_is_unchanged
    assert_equal "plain text, 1 line: ok", SoftFoundry::Display.safe("plain text, 1 line: ok")
    assert_equal "naïve café", SoftFoundry::Display.safe("naïve café")
  end

  def test_result_is_always_printable
    assert_predicate SoftFoundry::Display.safe("\e\u0085 ⁦"), :ascii_only?
  end

  def test_lists_are_truncated_with_a_count
    assert_equal "1; 2; 3; and 9 more", SoftFoundry::Display.list((1..12).map(&:to_s), limit: 3)
    assert_equal "1; 2", SoftFoundry::Display.list(%w[1 2], limit: 3)
    assert_equal "a<U+001B>b", SoftFoundry::Display.list(["a\eb"])
  end
end
