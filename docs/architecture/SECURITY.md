# Security baseline

Wave 1 establishes the following non-negotiable rules:

1. No API keys, Apple signing keys, provisioning profiles, certificates, `.env` files, or production credentials in git.
2. Match payloads are treated as untrusted input when decoded from Messages.
3. Future game engines must validate legal state transitions rather than trusting client-provided scores.
4. Future backend APIs must authorize by Pingo identity and rate-limit mutation endpoints.
5. StoreKit entitlements will be verified from signed transactions; UI state alone never grants paid content.
6. Pingo collects the minimum personal data required for profiles and friend-specific records.
