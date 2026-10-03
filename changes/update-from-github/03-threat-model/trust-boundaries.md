# Trust Boundaries

| Boundary | Inside | Outside | Controls crossing it |
| --- | --- | --- | --- |
| The repository's releases | What github.com/jmscholen/soft_foundry publishes under a `v<version>` tag | Anything else on the network | Fixed API address; HTTPS; only URLs the release itself gives (MIT-001) |
| The installed gem | `soft_foundry-<version>.gem` for the version asked for | Any other file the release or redirect hands back | Three-way version agreement: requested, release tag, file name (MIT-002) |
| The machine | Temporary directory and the Ruby's gem directory | Arbitrary paths from an archive | `tar` into a fresh temporary directory; only a top-level directory holding `soft_foundry.gemspec` is built (MIT-003) |
| The token | github.com and api.github.com | Any other host a redirect names | `Authorization` dropped for hosts not ending in github.com (MIT-004) |
