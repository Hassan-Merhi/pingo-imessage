# Pingo 1.0 App Store Checklist

Wave 7 makes the repository release-ready. The steps below are the external Apple/production actions that require account ownership or credentials and therefore must never be faked in source control.

## 1. Production services

- Create the production Cloudflare D1 database and apply all migrations.
- Deploy `pingo-api` with a real D1 binding.
- Confirm the HTTPS API base URL and public Pingo message URL are live.
- Run `ios/scripts/validate-release-env.sh` with the real production values.
- Do not ship an archive whose URLs contain `.invalid`, `example.com`, or `localhost`.

## 2. Apple identifiers

Register these exact identifiers in the Apple Developer account before archiving:

- Messages app: `com.pingo.messages`
- Messages extension: `com.pingo.messages.extension`

Enable only capabilities actually used by the targets. Signing certificates, provisioning profiles, `.p8` keys, `.p12` files, and `.mobileprovision` files must remain outside git.

## 3. App Store Connect app record

Create the iOS/iMessage app record for Pingo before uploading the first build. Use version `1.0.0`; build numbers must increase monotonically.

Copy English metadata from `release/app-store/metadata/en-US.json` and provide final public URLs for:

- Privacy Policy
- Support
- Marketing, if used

The repository contains publishable source text in `docs/PRIVACY.md` and `docs/SUPPORT.md`; host those pages on an HTTPS site before submission.

## 4. In-App Purchases

Create all seven entries in `release/app-store/iap-products.json` as **non-consumable** products. Product IDs must be copied exactly and may not be renamed after creation.

The local Xcode test catalog is `ios/StoreKit/Pingo.storekit`. Its local prices are test values only; choose final storefront prices in App Store Connect.

Before App Review, test at minimum:

- successful purchase for each entitlement family
- user cancellation
- pending/interrupted purchase
- restore with purchases
- restore with no purchases
- revoked/refunded entitlement no longer unlocks content

## 5. Privacy and age-rating answers

Use `release/app-store/PRIVACY-ANSWERS.md` as the source-of-truth review sheet. Re-check it against the production backend immediately before submission.

Pingo currently declares no advertising or cross-app tracking. Profile identifiers, gameplay/user content, and product interaction are used for app functionality.

Complete the App Store age-rating questionnaire based on the final content set. Pingo has no real-money gambling or wagering mechanics.

## 6. Accessibility declaration

Verify the release build with VoiceOver, Larger Text/Dynamic Type, Voice Control, sufficient contrast, and Reduce Motion where applicable before claiming support in App Store Connect.

## 7. Screenshots and review assets

Capture screenshots from a signed/release-equivalent build showing:

1. Pingo in the Messages app drawer / expanded game picker
2. 8-Ball turn flow
3. Chess or Sea Battle
4. Wave 6 expansion games
5. Best-of-series score
6. Profile/progression
7. Store and Restore Purchases

Do not show placeholder backend domains, debug labels, fake purchase states, private conversations, or personal contact information.

## 8. TestFlight

Archive with the real production environment and upload through Xcode/Transporter or the manual `App Store Release` GitHub Actions workflow after its `app-store` environment secrets are configured.

Use `release/app-store/TESTFLIGHT-NOTES.md` for the first beta group. Test on at least two physical iPhones with distinct Apple IDs and an actual iMessage conversation.

## 9. App Review

Use `release/app-store/REVIEW-NOTES.md` as the base review note. Clearly tell reviewers that Pingo is an iMessage app and is opened from Messages rather than as a normal home-screen app.

Attach the first seven IAPs to the submission as required and ensure their metadata is complete before sending the app version for review.

## 10. Final release gate

Before submission, all of the following must be true:

- `python3 scripts/validate-release.py` passes
- Swift core tests pass
- Worker + D1 checks pass
- unsigned Release simulator build passes
- production D1 migrations are applied
- production API and message URLs respond over HTTPS
- signed App Store archive succeeds
- StoreKit sandbox purchase + restore succeeds
- TestFlight smoke test succeeds on physical devices
- privacy/support URLs are public
- App Store metadata, screenshots, age rating, accessibility, privacy, and IAP metadata are complete

Wave 7 source code is complete when these release mechanics are present and CI is green; actual App Store submission remains an account-owner action.