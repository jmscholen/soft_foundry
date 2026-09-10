# Evaluation Plan

This change has no end-user-facing behavior or CLI journey of its own — it is a policy/documentation addition to `.ai/`, interpreted by whoever performs a `repository-discovery` assessment on a target repository. The equivalent of a "user journey" here is exercising the real scoring engine (`ControlPlane#score_maturity`) against the three states the new capability can legitimately take, and confirming the outcome matches the acceptance intent agreed with the user: IaC-absent is exempt, IaC-present-but-undashboarded blocks level 5, IaC-present-and-dashboarded passes.

Accessibility is not applicable: no UI surface is added or changed.
