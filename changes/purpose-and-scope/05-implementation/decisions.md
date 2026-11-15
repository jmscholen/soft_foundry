# Implementation Decisions

| Decision | Alternatives considered | Reason | Consequence |
| --- | --- | --- | --- |
| Put the Purpose section directly after the opening paragraph of each README | Replace the opening paragraph | The opening paragraphs describe what the files contain and are still accurate | The purpose is the first section a reader meets; no existing text is removed |
| Leave the "Agent: next implementation milestone" section of `README.md` as it is | Remove or update it | It is out of this change's scope, though it names a milestone that is long finished | Recorded as a finding for a later documentation change |
| The review skill points at the attack skill for the threat model | Repeat the full attacker text in the review skill | One place to change the threat model | A review session reads the attack skill's text; the control plane is in its read set |
| A weakness that needs repository write access goes in the attack handoff `notes`, with no severity | Record it as a minor finding | A finding with a severity is what later phases grade; the maintainer decided these are not attack results | Such notes reach learning but cannot block |
