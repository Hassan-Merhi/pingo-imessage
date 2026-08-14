# Wave 6 — Extra Games & Expansion Packs

Wave 6 expands Pingo from 10 to 22 playable iMessage games while keeping the same asynchronous, revision-protected match transport introduced in Waves 1–5.

## New games

### Arcade Expansion
- Bowling
- Penalty Shootout
- Archery
- Air Hockey
- Mini Racing
- Reaction Battle

### Word & Party Expansion
- Draw & Guess
- Word Hunt
- Anagrams
- Trivia

### Classics Expansion
- Crazy Eights
- Ludo

## Extra Game Engine

`PingoExtraGameEngine` is a deterministic turn engine for all 12 Wave 6 games. Each game has distinct rules and state, but all moves use a compact `PingoExtraGameMove` transport and complete/advance through the existing `PingoMatchReducer`.

The match UUID seeds deterministic random-looking outcomes such as penalty keepers, racing variance, Ludo rolls, card order, and reaction ready delays. Because the canonical state and deterministic seed travel with the iMessage card, both players can validate the same result without a continuous realtime connection.

Best-of-series continuation creates a new match UUID and therefore a fresh deterministic state while preserving the series ID and score.

## Store access

Wave 6 does not widen the original Premium Game Pack. Access is separated into four game entitlements:

- Premium Game Pack — Mini Golf, Sea Battle, Chess, Checkers, Connect Four
- Arcade Expansion — six Wave 6 arcade/precision games
- Word & Party Expansion — four Wave 6 word/party games
- Classics Expansion — Crazy Eights and Ludo

StoreKit 2 product identifiers are defined in source, but App Store Connect products, pricing, signing, and live purchase testing remain deferred until Wave 7 release work.

All game purchases are designed as one-time digital unlocks. Pingo has no coins, loot boxes, wagering, or real-money gambling mechanics.

## Hidden-information notes

Sea Battle remains the strongest hidden-information implementation because fleet coordinates stay only in the player's extension sandbox.

Crazy Eights carries both hands in the shared match state and the UI hides the opponent hand. Draw & Guess carries a deterministic prompt index and only displays the prompt to the drawer. Those two Wave 6 games therefore provide casual in-app secrecy, not cryptographic secrecy against a modified client. This tradeoff avoids introducing a server-authoritative hidden-state service in the expansion wave.

## UI

`PingoExtraGameView` provides game-specific SwiftUI controls while keeping the top-level view decomposed into small components to avoid SwiftUI type-checker blowups.

The Messages controller routes Wave 6 moves through the same `MSSession`, revision checks, result cards, progression recording, and Best-of continuation used by the first 10 games.

## Verification

Wave 6 tests cover catalog/entitlement separation, deterministic game outcomes, scoring and completion rules, card/Ludo state, message payload size, Random Game filtering, and fresh Best-of game state. The release gate remains:

1. Swift core regression suite
2. Worker + D1 checks
3. unsigned iMessage simulator build
4. synthetic pull-request merge candidate
5. post-merge `main` verification
