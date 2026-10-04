# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Name the file from the release's asset | Follow redirects and keep the final name; read Content-Disposition | The asset name is known before download and is what the version check should see; a final address is not a name | The asset name is validated by pattern at parse time and again before install |
| `bindir/gem` by path | `ruby -S gem`; `Gem.bin_path("rubygems-update")` | PATH is the wrong place to look for the running Ruby's gem command | Works from any directory and any shell |
