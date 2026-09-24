# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Four kinds with fixed pattern tables | Entropy detection; a model-based judge | Deterministic, explainable, fast enough to run in every gate; the floor a review can build on | A phrased-around attack or an unknown key shape is not caught, and the docs say so |
| Invisible text and secrets are errors everywhere; override and fetch-and-execute are errors only under `.ai/policies/` | One level per kind everywhere | A rule, a threat model, or an attack log legitimately quotes an attack; nothing under policies should | Warnings in old records, errors where it matters |
| The in-line marker exempts secrets, override, and fetch-and-execute, never invisible text | Exempt only quoted attacks; exempt everything | A documented example key is a legitimate quotation; invisible text has no legitimate use in a file an agent reads | One rule stated in the module comment and the README |
| A policy allowlist with a required reason for evidence that cannot be edited | Edit closed evidence; skip closed records | Anti-fudging forbids the edit; a leak in a closed record still matters | The canary is the first entry; `check` validates every entry |
| The gate scans the whole phase directory, evidence included | Required files only | A leaked key in a transcript is the case that matters most | Quoted attacks in transcripts are warnings, so records still pass |
| The evaluation harness sanitises its own transcript | Exempt this record's evidence; leave the findings | The evidence must say what happened without being the thing it describes; an exemption for our own record would be the wrong lesson | `<U+200B>` and `[masked]` appear in the transcript where the raw bytes would have |
| Promote learning-instincts' instincts through this record | Wait for a dedicated promotion change | The governance path exists to be used, and this is the next change; `learned.md` is then under the scan | Four sections in `learned.md`; the learning tests reset the fixture's ledger |
