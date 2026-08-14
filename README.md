# Pingo

Pingo is a family-friendly collection of competitive mini-games built specifically for Apple Messages/iMessage.

## Wave 1 status

Wave 1 establishes the production foundation:

- Reproducible iOS + Messages-extension project definition
- Standalone iMessage app container and Messages extension shell
- Shared Swift package (`PingoCore`)
- Original Pingo visual identity and app icon assets
- Responsive compact/expanded Messages UI
- Launch game catalog for 10 games
- Match-state and persistence primitives for future waves
- Architecture and backend boundaries
- Unit tests and GitHub Actions CI

No Apple Developer credentials or signing secrets are required for Wave 1. Bundle identifiers are placeholders and will be replaced during the release/signing phase.

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

The Xcode project is generated from `ios/project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen). Pingo keeps one square master icon in git; the Apple-required Messages extension icon variants are generated locally from that master before project generation.

```bash
brew install xcodegen
bash ios/scripts/generate-imessage-icons.sh
xcodegen generate --spec ios/project.yml
open ios/Pingo.xcodeproj
```

Select the **Pingo** scheme and an iPhone simulator. The `PingoMessagesExtension` target is embedded in the standalone iMessage app container; Pingo does not ship a normal home-screen iOS app.

## Repository policy

- `main` is expected to stay releasable.
- Development happens on phase/wave branches.
- Never commit signing certificates, provisioning profiles, `.env` files, API keys, or production secrets.

## Current architecture

See [`docs/architecture/WAVE-1.md`](docs/architecture/WAVE-1.md).
