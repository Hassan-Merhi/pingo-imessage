# Wave 5 Closure Corrections

This follow-up closes the review findings discovered after the original Wave 5 PR auto-merged.

- Progression sync now reconciles remote results per match instead of marking unseen match IDs processed from aggregate snapshots.
- Chess Best-of series alternate White/Black seats while keeping series scoring anchored to host/opponent identity.
- Regression coverage reproduces equal-count disjoint cross-device results and second-game chess seat alternation.
- `PingoIncomingMatchView.matchSubtitle` uses an explicit `return switch` so the full Xcode simulator build compiles under the current toolchain.

The correction branch passed Swift core tests, Worker + D1 checks, and the unsigned iMessage simulator build before this closure PR was opened.
