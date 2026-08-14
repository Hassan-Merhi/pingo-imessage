# Pingo

Pingo is a family-friendly collection of competitive mini-games built specifically for Apple Messages/iMessage.

## Current status — Waves 1–2

Wave 1 established the standalone iMessage project, shared Swift core, original Pingo branding, 10-game catalog, reproducible Xcode generation, and CI.

Wave 2 adds the reusable multiplayer and identity layer:

- iMessage challenge cards for all 10 launch games
- interactive `MSSession` continuation for accepted/updated matches
- versioned match state with revision-based stale-turn protection
- Pingo usernames and custom preset/emoji avatars
- local profiles with wins/losses/streak fields
- secure Keychain storage for backend tokens
- Cloudflare Worker + D1 backend for profiles, matches, revisions, rematches and opponent records
- Worker/D1 verification in CI alongside Swift tests and the full iMessage simulator build

Game-specific engines begin in Wave 3; Wave 2 deliberately provides the shared challenge/profile/match infrastructure they plug into.

No Apple Developer credentials or signing secrets are required yet. Production Cloudflare IDs/domains and Apple signing remain deferred until those accounts are configured.

## Launch catalog

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
- [`docs/architecture/SECURITY.md`](docs/architecture/SECURITY.md)
