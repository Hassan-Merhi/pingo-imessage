# Pingo

Pingo is a family-friendly collection of competitive mini-games built specifically for Apple Messages/iMessage.

## Current status — Waves 1–3

Wave 1 established the standalone iMessage project, shared Swift core, original Pingo branding, 10-game catalog, reproducible Xcode generation, and CI.

Wave 2 added the reusable multiplayer and identity layer: iMessage challenge cards, `MSSession` continuation, versioned/revision-protected match state, Pingo profiles/avatars, Keychain-backed tokens, and the Cloudflare Worker + D1 backend contract.

Wave 3 adds the first five complete game engines and playable iMessage interfaces:

- Tic-Tac-Toe — legal turns, wins and draws
- Connect Four — gravity, horizontal/vertical/diagonal wins and draws
- Checkers — forced captures, multi-jumps, kings and win detection
- Chess — legal-move filtering, check/checkmate, stalemate, castling, en passant, promotion, 50-move and insufficient-material draws
- Sea Battle — manual fleet placement/orientation, private fleet storage, public hit/miss/sunk tracking and victory detection

All five games use the Wave 2 match envelope and revision guard. A player makes a move inside Messages, Pingo prepares the updated interactive message in the compose field, and the player sends that card back to the opponent.

Sea Battle is deliberately different because its ship positions are secret. A player's five-ship fleet is validated and stored only in that player's Messages-extension sandbox. Fleet coordinates never enter the shared iMessage payload; shared state contains only readiness, pending shots and public hit/miss/sunk results. When a player receives an opponent shot, Pingo resolves it against the device-private fleet and can batch that resolution with the player's return shot into one outgoing card. A Sea Battle match therefore needs to continue on the device that holds that player's private fleet.

The remaining five launch games — 8-Ball, Cup Pong, Basketball, Darts and Mini Golf — stay visible in the launch catalog as upcoming until their physics wave is complete.

No Apple Developer credentials or signing secrets are required yet. Production Cloudflare IDs/domains and Apple signing remain deferred until those accounts are configured.

## Launch catalog

Playable now:

1. Sea Battle
2. Chess
3. Checkers
4. Connect Four
5. Tic-Tac-Toe

Next gameplay wave:

6. 8-Ball
7. Cup Pong
8. Basketball
9. Darts
10. Mini Golf

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
- [`docs/architecture/SECURITY.md`](docs/architecture/SECURITY.md)
