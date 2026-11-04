#!/bin/bash
# Installs the real 0.22.0 gem into a throwaway GEM_HOME and lets ITS updater
# take the rehearsed 0.23.0 gem. Nothing touches the machine's gems.
source /tmp/sf-eval-scripts/clean.sh
S=$1; G=$S/gemhome; mkdir -p $G $S/uhome; export SF_HOME=$S/uhome
CACHE=/Users/jscholen-iou/.asdf/installs/ruby/3.3.1/lib/ruby/gems/3.3.0/cache
gemenv() { clean GEM_HOME=$G GEM_PATH=$G "$@"; }
cd $S
echo "--- install the real 0.22.0"; gemenv gem install --local --no-document $CACHE/soft_foundry-0.22.0.gem 2>&1 | tail -2
echo "version: $(gemenv $G/bin/soft-foundry version)"
echo "0.22.0 has phase_seal.rb: $(ls $G/gems/soft_foundry-0.22.0/lib/soft_foundry/phase_seal.rb 2>/dev/null | wc -l | tr -d ' ')"
echo "--- 0.22.0: real read-only check against GitHub (latest there is still v0.17.0)"
gemenv $G/bin/soft-foundry update; echo "rc=$?"
echo "--- 0.22.0 updater: real download path, on the real v0.17.0 asset (redirects, name)"
cat > $S/dl.rb <<'RB'
require "soft_foundry/updater"
u = SoftFoundry::Updater.new
latest, err = u.send(:real_fetch)
rel = u.instance_variable_get(:@release)
puts "fetched=#{latest.inspect} err=#{err.inspect} asset=#{rel.gem_name}"
Dir.mktmpdir { |d| p = u.send(:real_download, rel.gem_url, d, rel.gem_name); puts "downloaded #{File.basename(p)} #{File.size(p)} bytes" }
RB
gemenv ruby $S/dl.rb; echo "rc=$?"
echo "--- 0.22.0 updater: GitHub's response stubbed as the v0.23.0 release, real gem install"
cat > $S/up.rb <<'RB'
require "soft_foundry/updater"
require "fileutils"; require "json"
built = ARGV[0]
body = JSON.dump("tag_name"=>"v0.23.0","tarball_url"=>"https://api.github.com/repos/jmscholen/soft_foundry/tarball/v0.23.0",
  "assets"=>[{"name"=>"soft_foundry-0.23.0.gem","browser_download_url"=>"https://github.com/jmscholen/soft_foundry/releases/download/v0.23.0/soft_foundry-0.23.0.gem"}])
resp = Net::HTTPOK.new("1.1","200","OK"); resp.instance_variable_set(:@read,true); resp.instance_variable_set(:@body,body)
u = SoftFoundry::Updater.new(http: ->(_uri,_h){resp}, downloader: ->(_url,dir,name){ File.join(dir,name).tap { |p| FileUtils.cp(built,p) } })
r = u.check; puts "current=#{r.current} latest=#{r.latest} update_available=#{r.update_available} error=#{r.error.inspect}"
i = u.install!(r.latest); puts "install ok=#{i.ok}"; puts i.message
exit(i.ok ? 0 : 1)
RB
gemenv ruby $S/up.rb $S/repo/soft_foundry-0.23.0.gem; echo "rc=$?"
echo "--- result on the throwaway GEM_HOME"
echo "version: $(gemenv $G/bin/soft-foundry version)"
gemenv gem list soft_foundry | tail -1
ls -l $G/gems/soft_foundry-0.23.0/lib/soft_foundry/phase_seal.rb | awk '{print "phase_seal.rb bytes="$5}'
gemenv $G/bin/soft-foundry update; echo "rc=$? (v0.17.0 is older than 0.23.0: up to date, not a downgrade)"
echo "gem-vs-tree lib diff: $(diff -rq $S/repo/lib $G/gems/soft_foundry-0.23.0/lib | wc -l | tr -d ' ') files"
