# Wave 3 — Board and strategy games

Wave 3 is the first gameplay wave. It keeps the Wave 2 transport/session/profile architecture intact and adds deterministic, serializable game engines for five titles.

## Shared gameplay contract

`PingoBoardGameEngine` is the adapter between a game-specific move and `PingoMatchEnvelope`.

1. Validate that the match is active, the revision is current and the actor owns the turn.
2. Decode the compact game state from `match.gameState`.
3. Apply the game rule engine.
4. Encode the resulting state.
5. Advance the turn through `PingoMatchReducer.submitTurn`, or close the match through `completeTurn`.
6. `MessagesViewController` packages the resulting envelope in the existing `MSSession` and inserts the updated interactive message into the compose field.

Checkers may keep the same player after a capture when a mandatory multi-jump remains. For that reason the reducer now permits the next player to be the current actor as long as that ID belongs to the match.

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

## Sea Battle

Each fleet uses five standard ship lengths: 5, 4, 3, 3 and 2. The state stores placements plus each player's fired cell indexes instead of two full 100-cell boards.

Rules/UI implemented:

- manual ship selection
- horizontal/vertical placement
- bounds and overlap validation
- local draft placement before sending
- one outgoing setup card for the whole fleet
- hidden opponent ships during play
- hit/miss tracking
- sunk-ship detection
- final victory when every opponent ship cell has been hit
- fleet reveal after match completion

## Tests

Wave 3 regression tests cover:

- Tic-Tac-Toe completion
- Connect Four win detection
- Checkers mandatory captures, multi-jumps and promotion
- Chess Fool's Mate, castling, en passant and promotion
- Sea Battle overlap rejection, fleet completion and final-hit victory
- compact initial state sizes

The repository CI continues to run the complete Swift core suite, Cloudflare Worker + D1 checks and the unsigned iMessage simulator build.
