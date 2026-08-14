# Pingo backend

Wave 2 introduces the production backend contract as a Cloudflare Worker backed by D1.

## Responsibilities

- passwordless Pingo guest identity bootstrap
- unique usernames and public profiles
- hashed bearer-token authentication and revocation-ready device tokens
- durable match membership and revision history
- server-side turn/revision validation for large or backend-backed game state
- resign/rematch flows
- overall, per-game, and opponent-specific records

Small iMessage match payloads remain message-first so a challenge can be opened directly from Messages. Larger future physics state can use the Worker/D1 match state path.

## Local checks

```bash
cd backend
npm install
npm run types
npm run typecheck
npm run migrate:local
npx wrangler deploy --dry-run --outdir dist
```

`wrangler.jsonc` intentionally contains a placeholder D1 database ID. Replace it only when the production Cloudflare account/database is created; never commit API tokens or secrets.

## Main routes

- `GET /v1/health`
- `POST /v1/bootstrap`
- `GET /v1/usernames/:username/available`
- `GET/PATCH /v1/me`
- `GET /v1/players/:id`
- `GET /v1/records/:opponentID`
- `GET/POST /v1/matches`
- `GET /v1/matches/:id`
- `POST /v1/matches/:id/accept`
- `POST /v1/matches/:id/state`
- `POST /v1/matches/:id/resign`
- `POST /v1/matches/:id/rematch`
