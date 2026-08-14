# Pingo App Privacy Review Sheet

This document maps the current Pingo implementation to App Store privacy disclosures. Re-verify it against production before every submission.

## Tracking

**Tracking:** No.

Pingo does not contain advertising SDKs, data brokers, cross-app tracking SDKs, or tracking domains in the current repository. `PrivacyInfo.xcprivacy` sets `NSPrivacyTracking` to false.

## Data linked to the user

### User ID — App Functionality

Pingo creates a player UUID and user-selected username. The backend stores the player ID, username, avatar selection, authentication token hash, and timestamps so the player can maintain identity and progression.

Suggested App Store Connect declaration:

- Data type: User ID
- Linked to user: Yes
- Used for tracking: No
- Purpose: App Functionality

### User Content / Gameplay Content — App Functionality

Match state and game-specific content are necessary to play. This can include board state, scores, turns, Draw & Guess drawings, and other gameplay payloads. iMessage also carries match cards between participants.

Suggested declaration:

- Data type: Other User Content / the closest current Gameplay Content category offered by App Store Connect
- Linked to user: Yes
- Used for tracking: No
- Purpose: App Functionality

### Product Interaction — App Functionality

Pingo stores gameplay statistics and progression such as wins, losses, draws, game counts, streaks, XP, achievements, match history, and opponent records.

Suggested declaration:

- Data type: Product Interaction
- Linked to user: Yes
- Used for tracking: No
- Purpose: App Functionality

## Purchases

StoreKit transaction verification is used on-device to derive entitlements. The current progression sync intentionally does not trust client-writable purchase entitlement data. If production backend behavior later begins storing transaction identifiers or purchase history, update the disclosure before submission.

## Diagnostics and hosting providers

Cloudflare hosts the Worker/D1 backend. Re-check production logging/analytics settings and any provider-side diagnostics before completing the final App Store privacy form. Do not claim a narrower disclosure than the live production configuration supports.

## Contacts, location, photos, microphone, camera

The current Pingo code does not request address-book contacts, precise/coarse location, photo library, microphone, or camera access. If any such capability is added later, update both the app permission strings and privacy disclosure before release.

## Required-reason APIs

The current privacy manifest has an empty `NSPrivacyAccessedAPITypes` array because Wave 7 does not intentionally use Apple's listed required-reason APIs directly. If a future SDK or code change adds one, supply the appropriate approved reason rather than suppressing the declaration.

## Review rule

The App Store Connect privacy answers describe the **production app and third-party partners**, not merely what is present in this repository. Re-run this review whenever backend logging, analytics, SDKs, authentication, or data retention changes.