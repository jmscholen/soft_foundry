# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Snapshot returns string-keyed Hashes, not new Data classes | `to_h` on each existing Data object; a serializer class per object | The consumer is JSON. One place decides what leaves the process, and the existing objects stay as they are | Callers index by string; the shape is tested by a JSON round trip |
| Closed records are not gated on the board | Gate all; cache gate results | 0.4 s per record, eighteen of twenty closed here; `ci` already skips them | A closed row shows recorded status and `evaluated: false`; detail still gates on request |
| A cell carries `status` (recorded) and `state` (one word after gating) | A single field | The handoff's claim and the gate's verdict are different facts, and the views colour by the verdict | Unevaluated rows repeat the status as the state |
| `skip_reason` is reported only for a pending phase | Report whenever the phase is skippable | A complete phase was not skipped | The explainer gets optionality from `workflow`, not from a change |
| Check descriptions live in `gate.rb` | A YAML file under `.ai/`; strings in the page | They describe code in that file; `.ai/` is copied into adopter repositories and is not the place for tool internals | `checks_for` repeats `evaluate`'s conditions; a test compares the two for a completed phase |
| `track_line` formats `Snapshot.track` | Leave the CLI's own logic and duplicate it | One source for the track state | Output verified byte-identical against `main` |
| Timeline uses recorded times only | Stitch in `git log` | The record is the claim; git history is a different source and needs a new wrapper | No close event (no `closed_at` is recorded); a later change may add one |
| Errors in a board row are reported with the root stripped | Let it raise; drop the row | One bad record must not hide nineteen good ones, and the message must not name a home directory | `change list --json` exits 0 with an `error` row |
