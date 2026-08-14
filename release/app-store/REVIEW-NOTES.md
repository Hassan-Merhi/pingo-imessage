# App Review Notes — Pingo 1.0

Pingo is an iMessage app. It is opened from inside the Apple Messages app rather than as a conventional home-screen application.

## How to open Pingo

1. Open Messages on an iPhone or iPad.
2. Open an iMessage conversation with another iMessage user.
3. Open the Messages apps/stickers interface and select Pingo.
4. Expand Pingo, choose a game, and tap Send Challenge.
5. Send the prepared Pingo message card.
6. On the second device/account, tap the Pingo card, accept, make a move, and send the updated card back.

Pingo is asynchronous. Each legal turn is serialized into the updated Pingo message and uses revision protection so stale cards cannot overwrite newer turns.

## Purchases

Pingo offers seven optional non-consumable unlocks. The store has a visible Restore Purchases action. There are no consumable currencies, loot boxes, wagering, or real-money gambling mechanics.

The five free games remain playable without purchase: 8-Ball, Cup Pong, Basketball, Darts, and Tic-Tac-Toe.

## Accounts

Pingo creates a lightweight player profile in-app. No reviewer username/password is required. A username/avatar can be edited from the profile screen.

## Sea Battle note

Sea Battle ship coordinates are stored privately in the local Messages-extension sandbox and are not included in the shared match payload. Continue a Sea Battle game on the device that created that player's fleet.

## Network

The submitted build must point at the production HTTPS API and Pingo message URLs. Review should never see `.invalid`, localhost, staging-only authentication, or debug endpoints.