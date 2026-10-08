# Deviations From Plan

1. **The RED test's quoting assertion was corrected after RED.** As committed in `af7da27`, the expected string read `x\;` in a double-quoted literal, which Ruby reads as `x;`, so it could never match a quoted command. It is now a single-quoted literal for `x\;\ touch\ PWNED`. The requirement it checks (REQ-SQ-002) is unchanged. Approval: review.
