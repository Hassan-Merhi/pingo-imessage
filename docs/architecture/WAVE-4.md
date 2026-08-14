# Wave 4 — Physics and Precision Games

Wave 4 completes Pingo's ten-game launch catalog by adding deterministic, iMessage-safe gameplay for 8-Ball, Cup Pong, Basketball, Darts and Mini Golf.

## Design principle

Pingo is asynchronous inside Messages. Physics therefore cannot depend on a continuously connected real-time server. Every shot is represented by compact player input (aim, power, or dart coordinates), simulated deterministically on the sender's device, and the resulting canonical game state is serialized into the revision-protected Pingo match envelope.

The opponent opens the newest card and continues from exactly that state. Stale revisions and out-of-turn submissions are rejected by the same match reducer used by Waves 2–3.

## Shared physics layer

`PingoPhysicsGameEngine` owns the five Wave 4 games and mirrors the board-game engine contract:

- validates active match/revision/turn ownership
- decodes or creates canonical initial state
- runs the deterministic game rule/simulation function
- serializes sorted-key JSON state
- advances the turn or completes the match through `PingoMatchReducer`

`PingoPlayableGameRegistry` is the union of the board/strategy engine and physics engine, so the launch catalog now reports all ten games as playable.

## 8-Ball

- normalized 2D table coordinates
- 16-ball rack with cue ball and 8-ball
- deterministic velocity integration, friction, cushion bounce and elastic ball collision approximation
- six pocket regions
- first-contact tracking
- solids/stripes assignment
- scratches respawn the cue ball
- own-group pocketing can retain the turn
- premature/illegal 8-ball pocket loses; legal 8-ball pocket wins
- state and post-break message payload are covered by the Messages URL-size regression test

The launch rules intentionally use a compact common-rules interpretation rather than league-specific called-pocket variants.

## Cup Pong

- six-cup triangular rack per player
- horizontal aim plus arc power maps to a deterministic landing point
- nearest active cup inside the scoring radius is removed
- turns alternate after each throw
- clearing all six opposing cups wins

## Basketball

- five-shot shootout per player
- release angle + power determine deterministic shot quality
- excellent releases score 3, good releases score 2, misses score 0
- after both players take five shots, highest score wins; equal scores draw

## Darts

- 301 straight-out mode
- three darts are submitted as one iMessage visit
- normalized board coordinates map to official-style 20-sector ordering
- inner/outer bull, triple ring and double ring scoring
- bust restores the score to the start of the visit
- exact zero wins

Double-out and Cricket remain optional later modes rather than launch requirements.

## Mini Golf

- nine fixed launch holes
- deterministic ball movement with friction and wall bounce
- rectangular obstacles
- low-speed cup capture
- per-hole strokes and total score
- eight unsuccessful strokes trigger a nine-stroke auto-finish so a match cannot deadlock on a hole
- after both players finish hole 9, lowest total wins; equal totals draw

## iMessage UI

`PingoPhysicsGameView` renders a dedicated interface for each game:

- 8-Ball table with live ball positions, aim and power controls
- Cup Pong rack with aim and arc power
- Basketball score/attempt display with release controls
- tappable Darts board collecting exactly three darts per visit
- Mini Golf course renderer with obstacles, balls, cup, aim and power

`MessagesViewController` routes physics moves separately from board moves but uses the same `MSSession`, interactive-message insertion and match envelope.

## Verification

Wave 4 CI includes:

- deterministic 8-Ball simulation regression
- Cup Pong hit detection
- Basketball ideal-release scoring
- Darts bull/bust/visit rules
- Mini Golf sinking behavior
- stale-revision rejection
- physics-engine state persistence
- all-ten-games-playable registry check
- initial payload-size checks for every physics game
- post-break 8-Ball payload-size check
- existing Waves 1–3 regression suite
- Worker + D1 typecheck/migrations/dry-run
- unsigned full iMessage simulator build

Production Apple signing, TestFlight and real Cloudflare production identifiers remain release-stage work.
