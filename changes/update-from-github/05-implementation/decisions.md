# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| GitHub releases as the source | RubyGems; a git clone | The maintainer does not want the gem on RubyGems; a release is a tag with an attached file | The repository needs a tag per version |
| Attached gem first, tagged source as fallback | Gem only; source only | The workflow attaches the gem; a release made by hand has none; building the source gives the same gem | Two code paths, both tested |
| Install under `RbConfig.ruby -S gem` | `gem` on PATH | The install must land where `soft-foundry` runs, which the global wrapper pins to one Ruby | Works from any repository |
| Three-way version agreement | Trust the tag | A release's JSON and a redirect are network input | A mismatched release is refused with the names shown |
| Tell the repository to run `init` | Run `init` from `update` | `init` has its own dry run, conflicts, and force; `update` should not take those decisions | One more line, one more command |
| A workflow on `v*` tags | Manual releases | Reproducible, tested, and the gem is built on CI's Ruby | Releasing is `git tag v<version> && git push --tags` |
