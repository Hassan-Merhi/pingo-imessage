# Wave 3 — Board and strategy games

Wave 3 is the first gameplay wave. It keeps the Wave 2 transport/session/profile architecture intact and adds deterministic game engines and iMessage interfaces for five titles.

## Shared gameplay contract

`PingoBoardGameEngine` is the adapter between a game-specific move and `PingoMatchEnvelope`.

1. Validate that the match is active, the revision is current and the actor owns the turn.
2. Decode the compact public game state from `match.gameState`.
3. Apply the game rule engine.
4. Encode the resulting public state.
5. Advance the turn through `PingoMatchReducer.submitTurn`, or close the match through `completeTurn`.
6. `MessagesViewController` packages the resulting envelope in the existing `MSSession` and inserts the updated interactive message into the compose field.

Checkers may keep the same player after a capture when a mandatory multi-jump remains. Sea Battle also briefly keeps the defender as the current actor after resolving an incoming shot so the defender can immediately take a return shot; the controller batches resolution + return shot into one outgoing iMessage card.

## Tic-Tac-Toe

The state is a compact nine-cell integer array. The engine rejects occupied/out-of-bounds cells, detects all eight winning lines and completes a full-board draw.

## Connect Four

The state is a 6×7 integer array. The engine applies gravity to the selected column and scans horizontal, vertical and both diagonal directions for four connected pieces.

## Checkers

The state uses an 8×8 integer board plus an optional forced continuation square. Rules implemented:

- diagonal movement on dark squares
- mandatory captures
- multi-jump continuation
- kings moving/capturing both directions
- promotion on the far rank
- win when the opponent has no pieces or no legal moves

## Chess

The chess board uses compact integer piece codes rather than per-piece UUIDs to keep iMessage payloads small. Rules implemented:

- legal piece movement and obstruction
- king-safety filtering
- check and checkmate
- stalemate
- kingside and queenside castling with attack-path validation
- en passant
- queen/rook/bishop/knight promotion
- castling-right updates after rook/king moves or rook capture
- 50-move draw
- common insufficient-material draws

Threefold-repetition history is intentionally not encoded in the current compact state because it requires historical-position tracking. It can be added later without changing the move API.

## Sea Battle privacy model

A shared iMessage payload must never contain both players' secret fleet coordinates. Merely hiding those coordinates in the UI would not be sufficient because the underlying interactive-message data is shared with both participants.

Wave 3 therefore separates **private fleet data** from **public match data**:

- each player arranges the standard 5/4/3/3/2 fleet locally;
- fleet coordinates are validated and stored only in that player's Messages-extension sandbox, keyed by match ID;
- `PingoSeaBattleState` sent through iMessage contains only `fleetReady`, public shot results and at most one pending shot coordinate;
- fleet coordinates are never encoded into `match.gameState`;
- when Player A fires, the shared state records a pending coordinate and gives Player B the turn;
- Player B resolves that coordinate against B's device-private fleet, producing only hit/miss/sunk information in public state;
- if B survives, B's return shot is applied in the same local batch and one updated iMessage card is sent back;
- if A's shot sinks B's final remaining ship cell, the resolver completes the match and the queued return shot is discarded.

This keeps hidden ship coordinates out of the opponent's iMessage payload while preserving one outgoing card per normal battle turn. The tradeoff is that a Sea Battle match must be continued on the device that holds that player's private fleet. If that private fleet is missing, Pingo fails closed and tells the player to continue on the original device rather than reconstructing or exposing the fleet.

Rules/UI implemented:

- manual ship selection
- horizontal/vertical placement
- strict board-edge and overlap validation
- device-private fleet persistence
- one outgoing setup card for the whole fleet
- hidden fleet coordinates excluded from shared message state
- pending-shot + defender-resolution protocol
- one-card defender resolution + return shot
- hit/miss tracking
- sunk-ship detection
- final victory when every private opponent ship cell has been hit

## Tests

Wave 3 regression tests cover:

- Tic-Tac-Toe completion
- Connect Four win detection
- Checkers mandatory captures, multi-jumps and promotion
- Chess Fool's Mate, castling, en passant and promotion
- Sea Battle overlap and edge-wrap rejection
- Sea Battle fleet validation and final-hit victory
- proof that private ship names/placements do not enter shared Sea Battle state
- Sea Battle resolve-then-return turn sequencing
- near-complete Sea Battle iMessage payload size
- compact initial state sizes

The repository CI continues to run the complete Swift core suite, Cloudflare Worker + D1 checks and the unsigned iMessage simulator build.
