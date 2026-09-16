# Exploration

Iterate on the change with the person until they accept it. This stage exists so that a feature can be shaped by trying it rather than by specifying it in advance; the lifecycle's assurance phases run afterwards, once, against what was accepted.

Each round: make the change, run the repository's ordinary tests, deploy to the **development** environment recorded under `environments:` in `.ai/repository.yml` (never any other environment; see `.ai/policies/human-boundaries.yml`), put it in front of the person, and append one entry to `exploration/iterations.yml` naming what they asked, what changed, the commit, and where it was deployed. Keep `02-specification/` as a living draft that says what the feature currently does and how it will be accepted; do not log deviations from it, change it.

Produce no verification, evaluation, attack, review, or judgment evidence. Nothing from this stage is evidence; the journal is a record of how the feature was shaped.

When the person says the feature is accepted, make sure `00-intake/` and `02-specification/` are complete with no `TBD`, then run `soft-foundry change vet`. From that commit on, the specification is locked and the phases from implementation onward apply exactly as on the gated track.
