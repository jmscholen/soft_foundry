# Threat Model

## Trust boundaries
See `trust-boundaries.md`.

## Externally controlled inputs
- The JSON GitHub returns for the latest release: tag name, asset names and URLs, tarball URL.
- The bytes downloaded from the asset or tarball URL, after GitHub's redirects.
- `GITHUB_TOKEN` from the environment.

## Authorization boundaries
Writing to the machine's gem directory is the user's own privilege; the command runs as them and only when `--yes` is given.

## Abuse cases
- A redirect sends the download to another host; a token is sent there.
- The release's JSON names a file that is not the gem, or a different version.
- The tarball extracts outside its directory or contains a different gemspec.
- Someone who can create a release on the repository ships a hostile gem (the repository's own trust).
- A network error or a 403 rate limit leaves the person without a clear answer.

## Injection / XSS / CSRF / SSRF / file risks
- Command injection: every subprocess is an argument list (`tar`, `gem build`, `gem install --local`); no value from the network is interpreted by a shell.
- File: downloads go to a temporary directory that is removed; the installed file must be named `soft_foundry-<version>.gem` for the version requested, which must equal the version the release names.
- SSRF: the only addresses contacted are the fixed releases API and the URLs GitHub returns for that release, over HTTPS; the `Authorization` header is dropped for any host other than github.com.

## Resource exhaustion and DoS
One request to check; a download of a few hundred kilobytes to install, with timeouts.

## Infrastructure exposure
The release workflow runs on GitHub with the default token, `contents: write`, only on `v*` tags, and only after the tag matches the code's version and the tests pass.

## Proposed attack cases
ATTACK-001 a release naming the wrong file or version; ATTACK-002 a source whose version differs from the release; ATTACK-003 a redirect off github.com with a token present.
