# Wave 2 — iMessage multiplayer + Pingo profiles

Wave 2 completes the reusable multiplayer and identity layer that future game engines plug into.

## Identity model

Pingo does not treat Apple's Messages participant UUID as a permanent account identifier. A Pingo profile has its own UUID, username, avatar, and aggregate stats. The local profile is persisted by the extension; a backend access token is stored in Keychain when online sync is configured.

The backend bootstrap is passwordless. It issues a cryptographically random bearer token and D1 stores only its SHA-256 hash.

## iMessage match model

`PingoMatchEnvelope` is schema-versioned and includes:

- match UUID and game ID
- status and expiry
- monotonically increasing revision
- turn number and current player
- creator and winner IDs
- player references
- opaque game-state bytes

`PingoMatchReducer` owns challenge, accept, turn, and resign transitions. Every mutation checks the expected revision so stale/out-of-order moves fail closed.

## Message transport

Small match payloads are encoded as a versioned JSON payload in `MSMessage.url` using URL-safe Base64. Pingo caps generated URLs below Apple's Messages URL limit. Each ongoing match reuses the selected message's `MSSession`, allowing a match card to evolve across turns.

Large future physics states are intentionally supported by the Worker/D1 state endpoint instead of forcing oversized data into Messages.

## Messages lifecycle

The extension handles activation, selection, receipt, send start, send cancellation, and presentation transitions. Current Wave 2 user flow:

1. Open Pingo in an iMessage conversation.
2. Pick any launch game.
3. Add a challenge card to the compose field and send it.
4. Recipient taps the card and accepts.
5. Acceptance continues the same `MSSession` and establishes both Pingo player IDs.
6. Future game waves attach their game-specific state/moves to this connected match.
7. Either player can resign an active match.

## Backend

Cloudflare Worker + D1 stores profiles, device-token hashes, matches, members, revision events, per-game stats, and opponent records. Prepared/bound D1 statements are used throughout. Match state updates require membership, active status, current turn, and exact revision.

The repository ships with `.invalid` API/message hostnames until production domains and the real D1 database ID are configured. This keeps Wave 2 buildable without secrets or an Apple/Cloudflare production account.

## Verification gates

CI must pass all three before Wave 2 merges:

- Swift core tests
- Cloudflare Worker type generation/typecheck + local D1 migration + dry-run bundle
- unsigned iMessage simulator build on macOS/Xcode
