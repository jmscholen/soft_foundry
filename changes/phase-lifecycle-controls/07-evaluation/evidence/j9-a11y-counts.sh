# usage: bash j9-a11y-counts.sh   (run from evidence/; counts lines of captured command output)
# macOS grep has no -P, so ruby counts the lines.
for f in a11y-captured-output.txt j1-reopen.txt j4-release.txt j8-remediation.txt; do
  ruby -e 'f=ARGV[0]; l=File.binread(f).lines; puts "#{f}: #{l.size} lines; with a non-ASCII byte: #{l.count { |x| x =~ /[\x80-\xff]/n }}; with an escape sequence: #{l.count { |x| x.include?("\e") }}"' $f
done
