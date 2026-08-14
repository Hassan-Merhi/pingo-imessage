import base from "./index";

type Stored = { state_json: string };
type TokenRow = { player_id: string };

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (new URL(request.url).pathname.replace(/\/+$/, "") !== "/v1/progression") {
      return base.fetch(request, env);
    }
    try {
      const playerID = await playerFor(request, env);
      if (request.method === "GET") {
        const row = await env.DB.prepare("SELECT state_json FROM player_progression WHERE player_id=?1 LIMIT 1").bind(playerID).first<Stored>();
        return reply({ progression: row ? JSON.parse(row.state_json) : null });
      }
      if (request.method !== "PUT") return reply({ error: { code: "METHOD_NOT_ALLOWED" } }, 405);
      if (Number(request.headers.get("content-length") ?? 0) > 64_000) return reply({ error: { code: "BODY_TOO_LARGE" } }, 413);
      const body = await request.json() as { progression?: unknown };
      const progression = clean(body.progression);
      const encoded = JSON.stringify(progression);
      if (new TextEncoder().encode(encoded).byteLength > 60_000) return reply({ error: { code: "PROGRESSION_TOO_LARGE" } }, 413);
      const p = progression as Record<string, any>, now = Date.now();
      await env.DB.batch([
        env.DB.prepare("INSERT INTO player_progression(player_id,state_json,updated_at) VALUES(?1,?2,?3) ON CONFLICT(player_id) DO UPDATE SET state_json=excluded.state_json,updated_at=excluded.updated_at").bind(playerID, encoded, now),
        env.DB.prepare("UPDATE players SET wins=?1,losses=?2,draws=?3,current_streak=?4,best_streak=?5,updated_at=?6 WHERE id=?7").bind(p.wins, p.losses, p.draws, p.currentStreak, p.bestStreak, now, playerID)
      ]);
      return reply({ progression });
    } catch {
      return reply({ error: { code: "PROGRESSION_SYNC_FAILED" } }, 400);
    }
  }
} satisfies ExportedHandler<Env>;

async function playerFor(request: Request, env: Env): Promise<string> {
  const token = (request.headers.get("authorization") ?? "").match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) throw new Error("auth");
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  const hash = Array.from(new Uint8Array(digest), x => x.toString(16).padStart(2, "0")).join("");
  const row = await env.DB.prepare("SELECT player_id FROM device_tokens WHERE token_hash=?1 AND revoked_at IS NULL LIMIT 1").bind(hash).first<TokenRow>();
  if (!row) throw new Error("auth");
  return row.player_id;
}

function clean(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("invalid");
  const v = value as Record<string, any>;
  const n = (k: string) => Number.isSafeInteger(v[k]) && v[k] >= 0 ? v[k] : 0;
  const arr = (k: string, max: number) => Array.isArray(v[k]) ? v[k].slice(0, max) : [];
  const counts: Record<string, number> = {};
  if (v.gameCounts && typeof v.gameCounts === "object" && !Array.isArray(v.gameCounts)) {
    for (const [k, raw] of Object.entries(v.gameCounts)) if (Number.isSafeInteger(raw) && (raw as number) >= 0) counts[k] = raw as number;
  }
  return {
    xp: n("xp"), wins: n("wins"), losses: n("losses"), draws: n("draws"),
    currentStreak: n("currentStreak"), bestStreak: Math.max(n("bestStreak"), n("currentStreak")),
    achievements: arr("achievements", 32), gameCounts: counts,
    opponentRecords: arr("opponentRecords", 100), history: arr("history", 100),
    processedMatchIDs: arr("processedMatchIDs", 500), updatedAt: Number(v.updatedAt) || Date.now()
  };
}

function reply(value: unknown, status = 200): Response {
  return Response.json(value, { status, headers: { "cache-control": "no-store", "x-content-type-options": "nosniff" } });
}
