# Pingo

Pingo is a family-friendly collection of competitive mini-games built specifically for Apple Messages/iMessage.

## Current status — Waves 1–6

Wave 1 established the standalone iMessage project, shared Swift core, original Pingo branding, reproducible Xcode generation, and CI.

Wave 2 added the reusable multiplayer and identity layer: iMessage challenge cards, `MSSession` continuation, versioned/revision-protected match state, Pingo profiles/avatars, Keychain-backed tokens, and the Cloudflare Worker + D1 backend contract.

Wave 3 added the first five board/strategy engines: Tic-Tac-Toe, Connect Four, Checkers, Chess, and Sea Battle.

Wave 4 added five deterministic physics/precision games: 8-Ball, Cup Pong, Basketball, Darts, and Mini Golf.

Wave 5 added Single/Best-of-3/Best-of-5 series, Random Game, XP/levels, achievements, W/L/D records, streaks, match/friend history, cosmetic inventory, StoreKit 2 purchase/restore plumbing, and authenticated progression sync. Paid ownership remains derived from verified StoreKit transactions rather than client-writable progression data.

Wave 6 expands the playable catalog to **22 games** with a deterministic extra-game engine and three additional one-time game packs.

All games use the same match envelope and revision guard. A player makes a move inside Messages, Pingo simulates or validates it locally, prepares the updated interactive message in the compose field, and the player sends that card back to the opponent.

## Playable catalog

### Original collection

1. 8-Ball
2. Cup Pong
3. Basketball
4. Darts
5. Mini Golf
6. Sea Battle
7. Chess
8. Checkers
9. Connect Four
10. Tic-Tac-Toe

### Wave 6 expansions

11. Bowling
12. Penalty Shootout
13. Archery
14. Air Hockey
15. Draw & Guess
16. Word Hunt
17. Anagrams
18. Trivia
19. Crazy Eights
20. Ludo
21. Mini Racing
22. Reaction Battle

## Game packs

Five original games remain free: 8-Ball, Cup Pong, Basketball, Darts, and Tic-Tac-Toe.

The original **Premium Game Pack** contains Mini Golf, Sea Battle, Chess, Checkers, and Connect Four.

Wave 6 adds three separate expansion entitlements:

- **Arcade Expansion:** Bowling, Penalty Shootout, Archery, Air Hockey, Mini Racing, Reaction Battle
- **Word & Party Expansion:** Draw & Guess, Word Hunt, Anagrams, Trivia
- **Classics Expansion:** Crazy Eights, Ludo

Pingo also defines the Neon, Space, and Gold Classics cosmetic packs. StoreKit identifiers are implemented, but live App Store Connect product creation/pricing and Apple signing remain Wave 7 release work.

Pingo has no coins, loot boxes, wagering, or real-money gambling mechanics.

## Multiplayer architecture

Physics and Wave 6 games are deterministic and asynchronous by design: player input is reduced into canonical game state that travels in the Pingo card, so opponents do not need a continuous real-time connection.

Sea Battle is deliberately different because fleet coordinates are secret. A player's fleet is stored only in that player's Messages-extension sandbox and never enters the shared iMessage payload.

Crazy Eights hides the opponent hand in the UI, and Draw & Guess shows the prompt only to the drawer, but those two Wave 6 games use shared deterministic state and therefore provide casual in-app secrecy rather than cryptographic secrecy against a modified client.

## Local development

### Core tests (macOS or Linux)

```bash
swift test
```

### iOS / iMessage app (macOS)

The Xcode project is generated from `ios/project.yml` using XcodeGen. Pingo keeps one square master icon in git; the Apple-required Messages extension icon variants are generated locally before project generation.

```bash
brew install xcodegen
bash ios/scripts/generate-imessage-icons.sh
xcodegen generate --spec ios/project.yml
open ios/Pingo.xcodeproj
```

Select the **Pingo** scheme and an iPhone simulator. `PingoMessagesExtension` is embedded in the standalone iMessage app container; Pingo does not ship a normal home-screen iOS app.

### Backend checks

```bash
cd backend
npm install
npm run types
npm run typecheck
npm run migrate:local
npx wrangler deploy --dry-run --outdir dist
```

## Repository policy

- `main` stays green/releasable.
- Development happens on phase/wave branches and merges through verified PRs.
- Never commit signing certificates, provisioning profiles, `.env` files, API keys, bearer tokens, or production secrets.

## Architecture

- [`docs/architecture/WAVE-1.md`](docs/architecture/WAVE-1.md)
- [`docs/architecture/WAVE-2.md`](docs/architecture/WAVE-2.md)
- [`docs/architecture/WAVE-3.md`](docs/architecture/WAVE-3.md)
- [`docs/architecture/WAVE-4.md`](docs/architecture/WAVE-4.md)
- [`docs/architecture/WAVE-5.md`](docs/architecture/WAVE-5.md)
- [`docs/architecture/WAVE-5-CLOSURE.md`](docs/architecture/WAVE-5-CLOSURE.md)
- [`docs/architecture/WAVE-6.md`](docs/architecture/WAVE-6.md)
- [`docs/architecture/SECURITY.md`](docs/architecture/SECURITY.md)
