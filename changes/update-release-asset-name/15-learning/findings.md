# Learning

## What this change taught us
- A stand-in exercised the real code but not the real conditions: the source tarball was named by its address, and the install ran from inside the repository, where the shim happened to be right. Both defects lived exactly in the gap between the stand-in and the real thing, which the previous record named as owed. Owing it was right; the lesson is to run the owed test before calling the feature usable.
- `ruby -S` is a PATH lookup. Under a version manager, PATH is the wrong place to find the running Ruby's own tools.

- A timing assertion with a fixed number of seconds measures the machine, not the code. The flaky test asserted "under two seconds" for a request that gates a board; under load that is not a property of the server.

## Reviewer/evaluator/attack findings worth generalizing
- REV-002: when a stand-in is used, write down what it does not reproduce, and test that part first when the real thing arrives.

## Proposed deterministic checks
None new.

## Proposed rule changes
None.

## Proposed harness evals
See `proposed-evals.md`.
