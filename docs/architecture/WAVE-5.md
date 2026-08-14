# Wave 5 — Competitive Progression, Series and Store Foundation

Wave 5 adds Pingo's persistent competitive and monetization layer while preserving the asynchronous iMessage architecture from Waves 1–4.

## Series
Challenges can be Single Game, Best of 3, or Best of 5. Optional `PingoSeriesState` travels in the match envelope with a stable series ID, score, game number, winner and completion state. New matches use schema v3; legacy schema-v2 cards still decode because series metadata is optional. Only the original series host can issue the next game, each continuation gets a new match ID and fresh game state, and the starting player alternates.

## Progression
Player-owned progression is kept outside the iMessage payload and tracks XP, level, W/L/D, current/best streak, achievements, per-game counts, recent history, friend-specific records and processed match IDs. Result application is idempotent. XP awards are 120 for a win, 60 for a draw and 30 for a loss, with 500 XP per level.

## Access and Random Game
Always-free launch games are 8-Ball, Cup Pong, Basketball, Darts and Tic-Tac-Toe. The Premium Game Pack unlocks Mini Golf, Sea Battle, Chess, Checkers and Connect Four. Random Game only selects games the player can access.

## Cosmetics and StoreKit 2
Cosmetic slots cover avatar, theme, pool cue, darts, golf ball, Cup Pong cups and basketball. Free defaults are always available. StoreKit 2 loading/purchase/current-entitlement/restore plumbing is included. The store is family friendly: no coins, random paid rewards, loot boxes, wagering or real-money gambling mechanics.

## Security and D1
On-device progression persists separately from the public profile and syncs through authenticated `/v1/progression`. D1 migration `0002_wave5.sql` adds progression storage and a reserved `store_entitlements` table. Paid entitlement ownership is deliberately excluded from client-synced progression, and Wave 5 exposes no client route capable of granting a paid entitlement.

## Verification
Regression coverage includes series scoring/continuation, host-only continuation, alternating starters, XP/stats/history/friend records, result idempotency, achievements, access policy, Random Game filtering, cosmetics entitlement/equip/revocation fallback, Store product mapping, legacy schema-v2 decoding, schema-v3 message round-trip/payload size, Waves 1–4 tests, Worker+D1 checks and the full unsigned iMessage simulator build with StoreKit linked.
