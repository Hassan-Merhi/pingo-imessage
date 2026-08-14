# Wave 7 — Release Readiness

Wave 7 turns the green 22-game Pingo codebase into a source-controlled App Store/TestFlight release package without committing Apple credentials or pretending external account actions happened inside git.

## Release identity

- Marketing version: `1.0.0`
- Initial build number: `1`
- Messages app bundle ID: `com.pingo.messages`
- Messages extension bundle ID: `com.pingo.messages.extension`
- Code signing: automatic at archive time with the Apple development team supplied outside git

The repository keeps `.invalid` development URLs as safe defaults. A signed App Store archive is blocked unless real HTTPS production API/message URLs are provided through build settings.

## Privacy

`ios/Resources/PrivacyInfo.xcprivacy` declares:

- no tracking
- no tracking domains
- no intentionally used required-reason APIs in Wave 7
- linked User ID for app functionality
- linked Gameplay Content for app functionality
- linked Product Interaction for app functionality

The manifest mirrors the D1 profile/match/progression model. `release/app-store/PRIVACY-ANSWERS.md` is the human review sheet for App Store Connect and must be checked against the live production configuration before each submission.

## StoreKit

`ios/StoreKit/Pingo.storekit` contains local non-consumable test products for all seven source-code product identifiers:

1. Premium Game Pack
2. Arcade Expansion
3. Word & Party Expansion
4. Classics Expansion
5. Neon Pack
6. Space Pack
7. Gold Classics

Local prices exist only for Xcode StoreKit testing. Production pricing and availability remain App Store Connect configuration.

`release/app-store/iap-products.json` is the source-controlled product creation/reference sheet. `scripts/validate-release.py` fails if source code, local StoreKit configuration, and App Store metadata product IDs drift apart.

## Release validation

`python3 scripts/validate-release.py` checks:

- 1.0.0 version/build contract
- bundle identifiers
- export-compliance declaration
- build-setting based production URLs
- privacy manifest structure and declared data categories
- exact StoreKit product-ID parity
- non-consumable product types
- App Store metadata length limits
- required release documents and workflows
- absence of tracked Apple signing material

`ios/scripts/validate-release-env.sh` is stricter for real archives and refuses `.invalid`, `example.com`, localhost, non-HTTPS service URLs, invalid team IDs, and invalid version/build values.

## Signed archive

`ios/scripts/app-store-archive.sh`:

1. validates production inputs
2. generates Messages icon variants
3. generates the Xcode project
4. archives the Release configuration for generic iOS
5. uses automatic signing with an externally supplied team ID
6. optionally authenticates provisioning with an App Store Connect API key
7. exports an App Store Connect IPA

Signing certificates and App Store Connect API keys stay outside the repository.

## Manual App Store upload workflow

`.github/workflows/app-store-release.yml` is intentionally `workflow_dispatch` only and runs in the protected `app-store` GitHub environment. It expects these secrets:

- `APPLE_DEVELOPMENT_TEAM`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8`
- `APPLE_DISTRIBUTION_CERTIFICATE_P12_BASE64`
- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`

The workflow validates release metadata, creates a temporary macOS keychain, imports the Apple Distribution certificate, writes the App Store Connect key only to temporary runner storage, produces the signed IPA, uploads it, preserves the IPA as a workflow artifact, and deletes signing material in an `always()` cleanup step.

## CI gate

Normal `Pingo CI` now includes a release-readiness validation step and compiles an unsigned **Release** simulator build. This gives every Wave 7 branch/PR a production-configuration compile check without requiring signing secrets.

The manual signed-upload workflow is never triggered by a normal push or pull request.

## App Store package

`release/app-store/` contains:

- English product-page metadata
- IAP product definitions
- privacy-answer review sheet
- TestFlight notes
- App Review notes
- production-value template
- full submission checklist

`docs/PRIVACY.md` and `docs/SUPPORT.md` provide source text for public HTTPS Privacy Policy and Support pages.

## What source control cannot complete

Wave 7 can make Pingo release-ready, but these require the account owner or live infrastructure and are deliberately not fabricated:

- creating/registering the Apple bundle IDs
- accepting Apple agreements/tax/banking requirements
- creating the App Store Connect app record
- creating/pricing the seven IAPs in App Store Connect
- configuring production Cloudflare D1 IDs/secrets and deploying the live Worker
- hosting the public privacy/support pages
- installing real Apple signing credentials into the protected GitHub environment
- uploading the first signed build and waiting for Apple processing
- TestFlight physical-device testing
- completing screenshots, age rating, accessibility declarations, and App Review submission

Those external actions are enumerated in `release/app-store/APP-STORE-CHECKLIST.md` so there is one deterministic handoff instead of hidden release knowledge.
