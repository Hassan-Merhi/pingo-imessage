# Cup Pong Phase 2 validation

Scope: aiming and throw controls only.

- Direct drag on the table chooses the predicted landing point.
- Horizontal drag maps to the existing -30...30 degree engine aim range.
- Vertical targeting maps to the existing 0.15...1.0 engine power range.
- A live quadratic trajectory and landing reticle preview the selected throw.
- A custom flick-up throw deck replaces the old system sliders and Throw button.
- Horizontal flick motion fine-tunes aim; upward flick distance controls power; release commits the existing `PingoAimShot` payload.
- No Cup Pong physics rules are changed in Phase 2.
- Other games remain unchanged.

Merge gate: Pingo CI and sideload-safe iPhone test IPA must both pass on the Phase 2 head.
