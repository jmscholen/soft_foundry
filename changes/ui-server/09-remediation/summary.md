# Remediation Summary

Trigger: the attack phase at `93b9422`.

| Finding | Fix | Test (RED `ae60e88`, GREEN `5d36e6f`) |
| --- | --- | --- |
| ATTACK-005: silent connections crowd out requests (503) | `UI::Server#admit` closes the connection that has waited longest without sending a request when all sixteen slots are taken; a newcomer is turned away only when every slot is busy answering | `test_silent_connections_cannot_crowd_out_a_request` |
| ATTACK-008: a non-mapping `metadata.yml` reported as a Ruby error | `Snapshot#metadata` raises "changes/<slug>/metadata.yml is not a mapping" | `test_a_metadata_file_that_is_not_a_mapping_is_named_plainly` |

After the fix every commit-bound phase was produced again at `5d36e6f`: the full suite, the evaluation transcript, and all nine attack cases. No requirement changed. The transition back to verification was followed: nothing recorded in this change predates the remediation commit except `evidence/attack-at-93b9422.log`, kept as the evidence of the violation.
