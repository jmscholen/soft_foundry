# Verification probe: ProcessRules.normalize_path on the spellings of AC-003 and a few more.
require "soft_foundry"
["./lib/app.rb", "lib//app.rb", "lib/./app.rb", "lib/x/../app.rb", "lib/app.rb/", " lib/app.rb ", "lib", "lib/",
 "/abs/lib/app.rb", "~/lib/app.rb", "lib/*.rb", "lib/a?.rb", "lib/[ab].rb", "lib/{a,b}.rb", "../outside.rb", "lib/../../x", ".", "", "C:\\lib\\app.rb", "lib\\app.rb", "LIB/app.rb"].each do |p|
  puts format("%-22s => %s", p.inspect, SoftFoundry::ProcessRules.normalize_path(p).inspect)
end
