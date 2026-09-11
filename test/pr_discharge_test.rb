# frozen_string_literal: true

require_relative "test_helper"

class PrDischargeTest < Minitest::Test
  def test_confirmed_ids_reads_a_single_id
    fetcher = ->(_pr) { [["looks good", "CONFIRMED: AC-060"], nil] }
    discharge = SoftFoundry::PrDischarge.new(".", fetcher: fetcher)
    assert_equal ["AC-060"], discharge.confirmed_ids(5)
  end

  def test_confirmed_ids_reads_a_comma_separated_list_across_comments
    fetcher = ->(_pr) { [["CONFIRMED: AC-060, AC-061", "unrelated", "CONFIRMED: AC-062"], nil] }
    discharge = SoftFoundry::PrDischarge.new(".", fetcher: fetcher)
    assert_equal %w[AC-060 AC-061 AC-062], discharge.confirmed_ids(5)
  end

  def test_confirmed_ids_is_empty_without_a_matching_comment
    fetcher = ->(_pr) { [["thanks!", "looks fine to me"], nil] }
    discharge = SoftFoundry::PrDischarge.new(".", fetcher: fetcher)
    assert_empty discharge.confirmed_ids(5)
  end

  def test_confirmed_ids_raises_on_fetch_error
    fetcher = ->(_pr) { [[], "gh pr view failed: not found"] }
    discharge = SoftFoundry::PrDischarge.new(".", fetcher: fetcher)
    assert_raises(RuntimeError) { discharge.confirmed_ids(5) }
  end

  def test_request_posts_a_body_naming_every_item
    posted = nil
    poster = ->(pr, body) { posted = [pr, body] }
    discharge = SoftFoundry::PrDischarge.new(".", poster: poster)
    discharge.request(5, [{"id" => "AC-060", "description" => "observed on production"}])
    pr, body = posted
    assert_equal 5, pr
    assert_includes body, "AC-060"
    assert_includes body, "observed on production"
    assert_includes body, "CONFIRMED:"
  end
end
