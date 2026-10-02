# frozen_string_literal: true

require_relative "test_helper"

# The page's safety and accessibility floor, checked on the files as
# shipped: what a browser would have to be driven to observe is in the
# change record's evaluation.
class UIAssetsTest < Minitest::Test
  ASSETS = File.expand_path("../lib/soft_foundry/ui/assets", __dir__)

  def asset(name) = File.read(File.join(ASSETS, name))

  # Record text reaches the page as data. No API that parses a string as
  # markup or code may appear in the script at all.
  def test_script_never_parses_strings_as_markup_or_code
    script = asset("app.js")
    %w[innerHTML outerHTML insertAdjacentHTML document.write DOMParser createContextualFragment srcdoc].each do |api|
      refute_includes script, api
    end
    refute_match(/\beval\s*\(/, script)
    refute_match(/\bnew\s+Function\b/, script)
    refute_match(/set(Timeout|Interval)\s*\(\s*["'`]/, script)
    assert_includes script, "textContent"
  end

  # The Content-Security-Policy allows only same-origin files, so the page
  # must not depend on anything inline or remote.
  def test_page_has_nothing_inline_and_nothing_remote
    page = asset("index.html")
    refute_match(/<script(?![^>]*\bsrc=)/i, page)
    refute_match(/<style/i, page)
    refute_match(/\sstyle=/i, page)
    refute_match(/\son[a-z]+=/i, page)
    [page, asset("app.css"), asset("app.js")].each { |text| refute_match(%r{https?://|//[a-z]}i, text.gsub(%r{^\s*(//|\*|/\*).*$}, "")) }
    assert_includes page, 'src="/app.js"'
    assert_includes page, 'href="/app.css"'
  end

  def test_page_declares_language_title_and_landmarks
    page = asset("index.html")
    assert_match(/<html lang="en">/, page)
    assert_match(%r{<title>[^<]+</title>}, page)
    assert_match(/<meta name="viewport" content="width=device-width, initial-scale=1">/, page)
    assert_match(/<header/, page)
    assert_match(/<main[^>]*id="main"/, page)
    assert_match(/<a[^>]*href="#main"/, page, "skip link")
    assert_match(/aria-live="polite"/, page)
  end

  def test_styles_cover_focus_dark_mode_and_reduced_motion
    css = asset("app.css")
    assert_includes css, ":focus-visible"
    assert_includes css, "prefers-color-scheme: dark"
    assert_includes css, "prefers-reduced-motion"
  end

  # Status is a word, with a shape beside it; never colour alone.
  def test_script_names_every_state_in_words
    script = asset("app.js")
    %w[pass warn fail stale in_progress blocked pending missing complete].each do |state|
      assert_match(/\b#{state}\b\s*:/, script, state)
    end
  end

  def test_page_offers_the_workflow_view_and_the_change_history
    page = asset("index.html")
    script = asset("app.js")
    assert_match(%r{<a href="#/workflow"[^>]*>Workflow</a>}, page)
    assert_includes script, '"/api/workflow"'
    %w[Timeline Spend Tracks].each { |heading| assert_includes script, "\"#{heading}\"" }
  end

  # Carried from ui-server's review (REV-024): pausing also stops the one
  # animation on the page.
  def test_pause_stops_the_animation
    assert_match(/\[data-paused\][^{]*\{[^}]*animation:\s*none/, asset("app.css"))
    assert_includes asset("app.js"), "data-paused"
  end

  def test_page_offers_the_running_view
    assert_match(%r{<a href="#/running"[^>]*>Running</a>}, asset("index.html"))
    assert_includes asset("app.js"), '"/api/processes"'
  end

  def test_assets_ship_in_the_gem
    spec = Gem::Specification.load(File.expand_path("../soft_foundry.gemspec", __dir__))
    %w[index.html app.css app.js].each { |name| assert_includes spec.files, "lib/soft_foundry/ui/assets/#{name}" }
    assert_includes spec.files, "lib/soft_foundry/ui/server.rb"
  end
end
