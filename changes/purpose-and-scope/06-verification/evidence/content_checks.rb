# frozen_string_literal: true

# Verification script for purpose-and-scope. Reads every file from a named
# commit with `git show`, never from the working tree, so the result is bound
# to that commit. Usage: ruby content_checks.rb <commit> [<intake-commit>]
# Prints one line per assertion (pass/fail) and exits 1 on any failure.

commit = ARGV.fetch(0)
intake = ARGV[1]
$failures = 0

def show(commit, path)
  out = IO.popen(["git", "show", "#{commit}:#{path}"], &:read)
  abort "error: cannot read #{path} at #{commit}" unless $?.success?
  out.force_encoding("UTF-8")
end

def assert(criterion, label, ok)
  $failures += 1 unless ok
  puts "#{ok ? 'pass' : 'fail'} #{criterion} #{label}"
end

# Text of a file before its first heading that describes commands or layout.
def before(text, heading_pattern)
  idx = text =~ heading_pattern
  idx ? text[0...idx] : nil
end

readme = show(commit, "README.md")
ai_readme = show(commit, ".ai/README.md")
attack = show(commit, ".ai/skills/adversarial-testing/SKILL.md")
review = show(commit, ".ai/skills/review/SKILL.md")

# --- AC-001 -----------------------------------------------------------------
# Headings following Purpose in each file; the first one describing commands
# or layout is the boundary the criterion names.
{ "README.md" => readme, ".ai/README.md" => ai_readme }.each do |name, text|
  headings = text.lines.grep(/^##? /).map(&:strip)
  puts "info AC-001 #{name} first headings: #{headings.first(4).inspect}"
  purpose_at = text =~ /^## Purpose$/
  # everything from "## Purpose" to the next level-2 heading
  section = purpose_at ? text[purpose_at..].sub(/\A## Purpose\n/, "").split(/^## /).first : ""
  second_heading = headings[1]
  assert "AC-001", "#{name}: Purpose is the first section after the title", second_heading == "## Purpose"
  assert "AC-001", "#{name}: states autonomous software factory", section.include?("Soft Foundry is an autonomous software factory")
  assert "AC-001", "#{name}: states what each gate checks is locked once a person approves it",
         section.include?("What each gate checks is locked once a person approves it")
  assert "AC-001", "#{name}: states the evidence phases look at the feature from the outside",
         section.include?("look at the feature from the outside") &&
         section.include?("Verification and evaluation ask what a legitimate user expects") &&
         section.include?("Attack asks what a bad actor would try through it")
  # --- AC-004 (README.md is the file the criterion names; .ai/README.md reported too)
  crit = name == "README.md" ? "AC-004" : "info-AC-004"
  three = section.include?("A person steps in at three points") &&
          section.include?("approves the specification before work starts") &&
          section.include?("accepts or rejects the result at the end") &&
          section.include?("remediation cap")
  lock = section.include?("lock and detect") && section.include?("the gate fails when a locked file changes") &&
         section.include?("No phase searches for ways around the lock")
  if crit == "AC-004"
    assert crit, "#{name}: names the three points where a person steps in", three
    assert crit, "#{name}: says the specification lock is lock and detect", lock
  else
    puts "info AC-004 #{name}: three points #{three ? 'present' : 'absent'}, lock and detect #{lock ? 'present' : 'absent'}"
  end
end

# --- AC-002 -----------------------------------------------------------------
assert "AC-002", "names the attacker as an outside party reaching the change through what it exposes",
       attack.include?("The attacker is an outside party who reaches the change through what it exposes")
%w[requests parameters uploads jobs webhooks].push("command arguments").each do |surface|
  assert "AC-002", "exposure list names #{surface}", attack =~ /through what it exposes:[^\n]*#{Regexp.escape(surface)}/
end
classes = ["Injection", "Cross-site scripting", "Broken authorization", "Identifier substitution",
           "Mass assignment", "Path traversal", "Server-side request forgery", "Data exposure",
           "Resource exhaustion"]
numbered = attack.lines.grep(/^\d+\. /)
assert "AC-002", "numbered list has exactly nine attack classes (found #{numbered.size})", numbered.size == 9
classes.each_with_index do |c, i|
  assert "AC-002", "attack class #{i + 1}: #{c}", numbered[i].to_s.start_with?("#{i + 1}. #{c}")
end
assert "AC-002", "repository-write tampering is out of scope",
       attack.include?("Out of scope: a party with write access to the repository editing the change record, the control plane or git history")
assert "AC-002", "it is noted as a follow-up, not recorded as an attack result",
       attack.include?("note it as a follow-up") && attack.include?("Do not record it as an attack result")

# --- AC-003 -----------------------------------------------------------------
assert "AC-003", "findings are graded against the attack threat model",
       review.include?("Grade findings against the attack threat model")
assert "AC-003", "a finding needing repository write access is never graded blocking or major",
       review.include?("A finding that needs write access to the repository (editing the change record, the control plane or git history) is never graded blocking or major")
assert "AC-003", "it is recorded as a follow-up", review.include?("Record it as a follow-up")

# --- AC-005 -----------------------------------------------------------------
files = { "README.md" => readme, ".ai/README.md" => ai_readme,
          ".ai/skills/adversarial-testing/SKILL.md" => attack, ".ai/skills/review/SKILL.md" => review }
files.each do |name, text|
  # Heading order: exactly one level-1 heading first; no level skipped going down.
  in_fence = false
  levels = []
  text.each_line do |l|
    in_fence = !in_fence if l.start_with?("```")
    next if in_fence
    levels << Regexp.last_match(1).size if l =~ /^(#+) \S/
  end
  skips = levels.each_cons(2).count { |a, b| b > a + 1 }
  assert "AC-005", "#{name}: starts with one level-1 heading and skips no level (#{levels.size} headings, #{skips} skips)",
         levels.first == 1 && levels.count(1) == 1 && skips.zero?
  # Hidden or control characters: C0 controls except tab/newline, DEL, C1,
  # zero-width, bidirectional controls, BOM, tag characters.
  hidden = text.each_char.select do |ch|
    o = ch.ord
    (o < 0x20 && ![0x09, 0x0A].include?(o)) || o == 0x7F || (0x80..0x9F).cover?(o) ||
      (0x200B..0x200F).cover?(o) || (0x202A..0x202E).cover?(o) || (0x2060..0x2069).cover?(o) ||
      o == 0xFEFF || (0xE0000..0xE007F).cover?(o)
  end
  assert "AC-005", "#{name}: valid UTF-8 with no hidden or control characters (found #{hidden.size})",
         text.valid_encoding? && hidden.empty?
end

if intake
  # Added lines only: symbols or colour words that could carry meaning alone,
  # and link text.
  added = IO.popen(["git", "diff", "-U0", intake, commit, "--", *files.keys], &:read).force_encoding("UTF-8")
                .lines.select { |l| l.start_with?("+") && !l.start_with?("+++") }
  puts "info AC-005 added lines in the four files: #{added.size}"
  non_ascii = added.join.each_char.reject(&:ascii_only?).uniq
  assert "AC-005", "added text is plain ASCII: no glyph or emoji stands in for a word (non-ASCII: #{non_ascii.inspect})", non_ascii.empty?
  colour = added.grep(/\b(red|green|yellow|amber|orange|blue|colou?r(ed)?)\b/i)
  assert "AC-005", "added text makes no reference to colour (#{colour.size} lines)", colour.empty?
  links = added.join.scan(/\[([^\]]*)\]\(([^)]*)\)/)
  bad = links.select { |t, _| t.strip =~ /\A(here|click here|this|link|more)\z/i }
  assert "AC-005", "added text has no vague link text (#{links.size} links, #{bad.size} vague)", bad.empty?

  # --- AC-006 (diff part) ---------------------------------------------------
  paths = IO.popen(["git", "diff", "--name-only", intake, commit], &:read).lines.map(&:strip)
  code = paths.grep(%r{\A(lib|exe|test)/})
  outside_record = paths.reject { |p| p.start_with?("changes/") }
  puts "info AC-006 paths changed outside changes/: #{outside_record.inspect}"
  assert "AC-006", "no path under lib/, exe/ or test/ in the diff from #{intake[0, 7]} (#{paths.size} paths, #{code.size} under code)", code.empty?
end

puts "summary: #{$failures} failed"
exit($failures.zero? ? 0 : 1)
