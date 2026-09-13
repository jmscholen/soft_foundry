# Deviations

None from the request. Two defects were fixed along the way (see 05-implementation/log.md, IMP-1 and IMP-2); neither is a deviation from scope. IMP-1 (`change new` corrupting `metadata.yml` for a title containing ": ") was hit by this change's own record and blocked every subsequent command, so it had to be fixed to proceed; IMP-2 (the shell notice lost to `exec` before a buffered stdout flushed) was this change's own headline behavior failing end to end, found by evaluation before shipping.
