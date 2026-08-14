# Wave 1 — Foundation and Branding

## Goal

Create a stable, testable base for Pingo before game-specific or account-specific features are added.

## Decisions

### 1. iMessage-native architecture

Pingo is built as a standalone iMessage app (`application.messages`) with an embedded Messages extension (`app-extension.messages`), not as a normal home-screen iOS app. The Messages extension owns the in-conversation experience and subclasses `MSMessagesAppViewController`. SwiftUI is hosted inside that controller so we keep direct access to the Messages framework lifecycle while building the interface in SwiftUI.

### 2. Shared core package

`PingoCore` is a platform-light Swift package. It owns:

- Brand constants
- Game identifiers and launch catalog
- Versioned match-envelope primitives
- Serialization
- Local key/value persistence abstraction

It deliberately does **not** import `Messages`, `SwiftUI`, StoreKit, or a backend SDK. This keeps rules/test logic portable and independently testable.

### 3. Versioned match envelope from day one

Every future game state travels inside a `PingoMatchEnvelope` with a schema version, match UUID, game identifier, status, turn number, player references, timestamps, and opaque game-state bytes. Wave 2 will map this envelope into `MSMessage` / `MSSession` payloads.

### 4. Backend boundary

Wave 1 does not require a live backend. Profiles, stats, entitlements, and friend-specific records are future server-owned capabilities. The codebase remains provider-neutral in Wave 1 so we can finalize authentication and server trust boundaries before shipping personal data.

Current planned backend responsibilities for later waves:

- Pingo profile and username uniqueness
- Public-safe avatar/profile metadata
- Server-authoritative aggregate stats and achievements
- Cosmetic inventory and premium-pack entitlements
- Abuse/rate-limit controls

Game turns remain iMessage-first rather than requiring an always-online real-time game server.

### 5. Monetization boundary

All ten V1 launch games are represented as free. StoreKit and premium game packs are intentionally deferred to the monetization wave.

### 6. Branding

Original palette:

- Ink `#19172B`
- Pingo Purple `#6657E8`
- Ping Teal `#28C7B7`
- Surface `#F7F6FF`
- Highlight `#FFCC66`

The mark combines a conversation bubble with two game-like dots and a speech tail. It intentionally avoids GamePigeon artwork or brand trade dress.

## Directory map

```text
pingo-imessage/
├── Sources/PingoCore/
├── Tests/PingoCoreTests/
├── ios/
│   ├── Pingo/
│   ├── PingoMessagesExtension/
│   ├── SharedUI/
│   ├── Resources/
│   └── project.yml
├── Brand/
├── backend/
├── docs/
└── .github/workflows/
```

## Acceptance criteria

Wave 1 is complete when:

- [x] The 10-game catalog is represented in one shared model.
- [x] The match envelope round-trips through a versioned codec.
- [x] A standalone iMessage app container exists.
- [x] A `MSMessagesAppViewController` Messages extension shell exists.
- [x] Compact and expanded Messages layouts exist.
- [x] Original logo/icon assets exist.
- [x] Project generation is reproducible with XcodeGen.
- [x] Core tests pass under Swift 6.
- [x] CI validates core tests and an unsigned iOS simulator build on macOS.
- [x] Secrets/signing material are excluded from git.

## Deferred by design

These are not Wave 1 defects:

- Sending an `MSMessage` challenge (Wave 2)
- Usernames/profiles/backend deployment (Wave 2/3)
- Any playable game implementation (Wave 3+)
- StoreKit purchases (monetization wave)
- Apple Developer signing and App Store submission (release wave)
