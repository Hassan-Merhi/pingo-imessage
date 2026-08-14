const GAMES = new Set(["eightBall","cupPong","basketball","darts","miniGolf","seaBattle","chess","checkers","connectFour","ticTacToe"]);
const RESERVED = new Set(["admin","administrator","pingo","support","system","moderator","official"]);
const USERNAME = /^[a-z0-9_]{3,20}$/;
const MAX_STATE_BYTES = 32_000;
const TTL = 7 * 24 * 60 * 60 * 1000;

type PlayerRow = { id:string; username:string; avatar_kind:"preset"|"emoji"; avatar_value:string; avatar_background:string; wins:number; losses:number; draws:number; current_streak:number; best_streak:number; created_at:number; updated_at:number };
type MatchRow = { id:string; game_id:string; status:"awaitingOpponent"|"active"|"completed"|"resigned"|"expired"; revision:number; turn_number:number; created_by_player_id:string; current_player_id:string|null; winner_player_id:string|null; state_base64:string; created_at:number; updated_at:number; expires_at:number };
type Avatar = { kind:"preset"|"emoji"; value:string; background:string };
type Auth = { player:PlayerRow; tokenHash:string };

class APIError extends Error { constructor(readonly status:number, readonly code:string, message:string){ super(message); } }

export default {
  async fetch(request:Request, env:Env):Promise<Response> {
    const requestID = crypto.randomUUID();
    const started = Date.now();
    try {
      const response = await route(request, env);
      console.log(JSON.stringify({event:"request",requestID,method:request.method,path:new URL(request.url).pathname,status:response.status,durationMs:Date.now()-started}));
      return response;
    } catch (error) {
      const e = error instanceof APIError ? error : new APIError(500,"INTERNAL_ERROR","Pingo could not complete the request");
      console.error(JSON.stringify({event:"request_error",requestID,status:e.status,code:e.code,error:error instanceof Error?error.message:String(error)}));
      return json({error:{code:e.code,message:e.message},requestID},e.status);
    }
  }
} satisfies ExportedHandler<Env>;

async function route(request:Request, env:Env):Promise<Response> {
  const url = new URL(request.url); const path = url.pathname.replace(/\/+$/,"" ) || "/";
  if(request.method==="GET" && path==="/v1/health") return json({ok:true,service:"pingo-api"});
  if(request.method==="POST" && path==="/v1/bootstrap") return json(await bootstrap(env,await body<Record<string,unknown>>(request)),201);
  if(request.method==="GET" && path.startsWith("/v1/usernames/") && path.endsWith("/available")) {
    const name=canonical(decodeURIComponent(path.slice(14,-10))); const found=await env.DB.prepare("SELECT id FROM players WHERE username=?1 COLLATE NOCASE LIMIT 1").bind(name).first();
    return json({username:name,available:found===null});
  }
  const auth=await requireAuth(request,env);
  await env.DB.prepare("UPDATE device_tokens SET last_used_at=?1 WHERE token_hash=?2").bind(Date.now(),auth.tokenHash).run();
  if(request.method==="GET" && path==="/v1/me") return json({profile:playerJSON(auth.player)});
  if(request.method==="PATCH" && path==="/v1/me") return json({profile:playerJSON(await patchProfile(env,auth.player,await body<Record<string,unknown>>(request)))});
  if(request.method==="GET" && path.startsWith("/v1/players/")){ const id=path.slice(12); uuid(id); return json({profile:playerJSON(await getPlayer(env,id))}); }
  if(request.method==="GET" && path.startsWith("/v1/records/")){ const id=path.slice(12); uuid(id); const r=await env.DB.prepare("SELECT * FROM opponent_records WHERE player_id=?1 AND opponent_id=?2").bind(auth.player.id,id).first<Record<string,number|string|null>>(); return json({record:r??{player_id:auth.player.id,opponent_id:id,wins:0,losses:0,draws:0,current_streak:0,best_streak:0,last_played_at:null}}); }
  if(request.method==="GET" && path==="/v1/matches"){ const rows=await env.DB.prepare("SELECT m.* FROM matches m JOIN match_players mp ON mp.match_id=m.id WHERE mp.player_id=?1 ORDER BY m.updated_at DESC LIMIT 100").bind(auth.player.id).all<MatchRow>(); return json({matches:rows.results.map(matchJSON)}); }
  if(request.method==="POST" && path==="/v1/matches") return json({match:matchJSON(await createMatch(env,auth.player,await body<Record<string,unknown>>(request)))},201);
  const m=path.match(/^\/v1\/matches\/([0-9a-f-]+)(?:\/(accept|state|resign|rematch))?$/i);
  if(m){ uuid(m[1]); const id=m[1], action=m[2];
    if(request.method==="GET"&&!action){ await member(env,id,auth.player.id); return json({match:matchJSON(await getMatch(env,id))}); }
    if(request.method==="POST"&&action==="accept") return json({match:matchJSON(await accept(env,id,auth.player))});
    if(request.method==="POST"&&action==="state") return json({match:matchJSON(await state(env,id,auth.player.id,await body<Record<string,unknown>>(request)))});
    if(request.method==="POST"&&action==="resign") return json({match:matchJSON(await resign(env,id,auth.player.id))});
    if(request.method==="POST"&&action==="rematch") return json({match:matchJSON(await rematch(env,id,auth.player.id))},201);
  }
  throw new APIError(404,"NOT_FOUND","Route not found");
}

async function bootstrap(env:Env,b:Record<string,unknown>){
  const id=typeof b.playerID==="string"?b.playerID:crypto.randomUUID(); uuid(id);
  const name=typeof b.username==="string"?canonical(b.username):`pingo_${id.replaceAll("-","").slice(0,8)}`;
  const avatar=avatarOf(b.avatar); const now=Date.now(), token=randomToken(), hash=await sha256(token);
  try { await env.DB.batch([
    env.DB.prepare("INSERT INTO players(id,username,avatar_kind,avatar_value,avatar_background,created_at,updated_at) VALUES(?1,?2,?3,?4,?5,?6,?6)").bind(id,name,avatar.kind,avatar.value,avatar.background,now),
    env.DB.prepare("INSERT INTO device_tokens(id,player_id,token_hash,created_at,last_used_at) VALUES(?1,?2,?3,?4,?4)").bind(crypto.randomUUID(),id,hash,now)
  ]); } catch { throw new APIError(409,"PROFILE_EXISTS","That Pingo identity or username is already registered"); }
  return {accessToken:token,profile:playerJSON(await getPlayer(env,id))};
}
async function requireAuth(request:Request,env:Env):Promise<Auth>{ const token=(request.headers.get("authorization")??"").match(/^Bearer\s+(.+)$/i)?.[1]; if(!token) throw new APIError(401,"AUTH_REQUIRED","A Pingo access token is required"); const hash=await sha256(token); const player=await env.DB.prepare("SELECT p.* FROM players p JOIN device_tokens t ON t.player_id=p.id WHERE t.token_hash=?1 AND t.revoked_at IS NULL LIMIT 1").bind(hash).first<PlayerRow>(); if(!player) throw new APIError(401,"INVALID_TOKEN","The Pingo access token is invalid or revoked"); return {player,tokenHash:hash}; }
async function patchProfile(env:Env,p:PlayerRow,b:Record<string,unknown>){ const name=typeof b.username==="string"?canonical(b.username):p.username; const a=b.avatar===undefined?{kind:p.avatar_kind,value:p.avatar_value,background:p.avatar_background}:avatarOf(b.avatar); try{ await env.DB.prepare("UPDATE players SET username=?1,avatar_kind=?2,avatar_value=?3,avatar_background=?4,updated_at=?5 WHERE id=?6").bind(name,a.kind,a.value,a.background,Date.now(),p.id).run(); }catch{throw new APIError(409,"USERNAME_TAKEN","That Pingo username is already taken");} return getPlayer(env,p.id); }

async function createMatch(env:Env,p:PlayerRow,b:Record<string,unknown>){ const game=String(b.gameID??""); if(!GAMES.has(game)) throw new APIError(400,"INVALID_GAME","Unknown Pingo game"); const id=typeof b.matchID==="string"?b.matchID:crypto.randomUUID(); uuid(id); const now=Date.now(); await env.DB.batch([
  env.DB.prepare("INSERT INTO matches(id,game_id,status,revision,turn_number,created_by_player_id,state_base64,created_at,updated_at,expires_at) VALUES(?1,?2,'awaitingOpponent',0,0,?3,'',?4,?4,?5)").bind(id,game,p.id,now,now+TTL),
  env.DB.prepare("INSERT INTO match_players(match_id,player_id,seat,joined_at) VALUES(?1,?2,0,?3)").bind(id,p.id,now),
  env.DB.prepare("INSERT INTO match_events(id,match_id,revision,actor_player_id,kind,created_at) VALUES(?1,?2,0,?3,'challenge',?4)").bind(crypto.randomUUID(),id,p.id,now)
]); return getMatch(env,id); }
async function accept(env:Env,id:string,p:PlayerRow){ const match=await getMatch(env,id); if(match.status!=="awaitingOpponent") throw new APIError(409,"MATCH_NOT_JOINABLE","This challenge is no longer joinable"); if(match.created_by_player_id===p.id) throw new APIError(409,"SELF_CHALLENGE","You cannot accept your own challenge"); const now=Date.now(), rev=match.revision+1; try{await env.DB.batch([
  env.DB.prepare("UPDATE matches SET status='active',revision=?1,current_player_id=created_by_player_id,updated_at=?2 WHERE id=?3 AND status='awaitingOpponent' AND revision=?4").bind(rev,now,id,match.revision),
  env.DB.prepare("INSERT INTO match_players(match_id,player_id,seat,joined_at) VALUES(?1,?2,1,?3)").bind(id,p.id,now),
  env.DB.prepare("INSERT INTO match_events(id,match_id,revision,actor_player_id,kind,created_at) VALUES(?1,?2,?3,?4,'accepted',?5)").bind(crypto.randomUUID(),id,rev,p.id,now)
]);}catch{throw new APIError(409,"MATCH_ALREADY_ACCEPTED","Another player already accepted this challenge");} return getMatch(env,id); }
async function state(env:Env,id:string,actor:string,b:Record<string,unknown>){ const match=await getMatch(env,id); await member(env,id,actor); const expected=Number(b.expectedRevision), next=String(b.nextPlayerID??""), encoded=String(b.stateBase64??""); uuid(next); if(match.status!=="active") throw new APIError(409,"MATCH_NOT_ACTIVE","Match is not active"); if(match.revision!==expected) throw new APIError(409,"STALE_REVISION","A newer move already exists"); if(match.current_player_id!==actor) throw new APIError(409,"NOT_YOUR_TURN","It is not this player's turn"); await member(env,id,next); if(next===actor) throw new APIError(400,"INVALID_NEXT_PLAYER","Next player must be the opponent"); if(decode64(encoded).byteLength>MAX_STATE_BYTES) throw new APIError(413,"STATE_TOO_LARGE","Game state is too large"); const now=Date.now(), rev=expected+1; const results=await env.DB.batch([
  env.DB.prepare("UPDATE matches SET revision=?1,turn_number=turn_number+1,current_player_id=?2,state_base64=?3,updated_at=?4 WHERE id=?5 AND revision=?6 AND current_player_id=?7 AND status='active'").bind(rev,next,encoded,now,id,expected,actor),
  env.DB.prepare("INSERT INTO match_events(id,match_id,revision,actor_player_id,kind,created_at) VALUES(?1,?2,?3,?4,'turn',?5)").bind(crypto.randomUUID(),id,rev,actor,now)
]); if((results[0].meta.changes??0)!==1) throw new APIError(409,"STALE_REVISION","A newer move already exists"); return getMatch(env,id); }
async function resign(env:Env,id:string,actor:string){ const match=await getMatch(env,id); await member(env,id,actor); if(match.status!=="active") throw new APIError(409,"MATCH_NOT_ACTIVE","Match is not active"); const ids=await members(env,id), winner=ids.find(x=>x!==actor)??null, now=Date.now(), rev=match.revision+1; await env.DB.batch([
  env.DB.prepare("UPDATE matches SET status='resigned',revision=?1,current_player_id=NULL,winner_player_id=?2,updated_at=?3 WHERE id=?4 AND revision=?5 AND status='active'").bind(rev,winner,now,id,match.revision),
  env.DB.prepare("INSERT INTO match_events(id,match_id,revision,actor_player_id,kind,created_at) VALUES(?1,?2,?3,?4,'resigned',?5)").bind(crypto.randomUUID(),id,rev,actor,now)
]); if(winner) await result(env,match.game_id,winner,actor,now); return getMatch(env,id); }
async function rematch(env:Env,oldID:string,actor:string){ const old=await getMatch(env,oldID), ids=await members(env,oldID); if(!ids.includes(actor)) throw new APIError(403,"NOT_A_MATCH_PLAYER","Only match players can request a rematch"); if(!["completed","resigned"].includes(old.status)||ids.length!==2) throw new APIError(409,"MATCH_NOT_FINISHED","A two-player finished match is required"); const id=crypto.randomUUID(),now=Date.now(),first=ids[(old.turn_number+1)%2]; await env.DB.batch([
  env.DB.prepare("INSERT INTO matches(id,game_id,status,revision,turn_number,created_by_player_id,current_player_id,state_base64,created_at,updated_at,expires_at,rematch_of_match_id) VALUES(?1,?2,'active',1,0,?3,?4,'',?5,?5,?6,?7)").bind(id,old.game_id,actor,first,now,now+TTL,oldID),
  env.DB.prepare("INSERT INTO match_players(match_id,player_id,seat,joined_at) VALUES(?1,?2,0,?4),(?1,?3,1,?4)").bind(id,ids[0],ids[1],now),
  env.DB.prepare("INSERT INTO match_events(id,match_id,revision,actor_player_id,kind,payload_json,created_at) VALUES(?1,?2,1,?3,'rematch',?4,?5)").bind(crypto.randomUUID(),id,actor,JSON.stringify({oldMatchID:oldID}),now)
]); return getMatch(env,id); }

async function result(env:Env,game:string,winner:string,loser:string,now:number){ for(const [id,opp,win] of [[winner,loser,1],[loser,winner,0]] as const){ await env.DB.batch([
  env.DB.prepare("UPDATE players SET wins=wins+?1,losses=losses+?2,current_streak=CASE WHEN ?1=1 THEN current_streak+1 ELSE 0 END,best_streak=MAX(best_streak,CASE WHEN ?1=1 THEN current_streak+1 ELSE 0 END),updated_at=?3 WHERE id=?4").bind(win,1-win,now,id),
  env.DB.prepare("INSERT INTO game_stats(player_id,game_id,wins,losses,current_streak,best_streak) VALUES(?1,?2,?3,?4,?3,?3) ON CONFLICT(player_id,game_id) DO UPDATE SET wins=wins+excluded.wins,losses=losses+excluded.losses,current_streak=CASE WHEN excluded.wins=1 THEN current_streak+1 ELSE 0 END,best_streak=MAX(best_streak,CASE WHEN excluded.wins=1 THEN current_streak+1 ELSE 0 END)").bind(id,game,win,1-win),
  env.DB.prepare("INSERT INTO opponent_records(player_id,opponent_id,wins,losses,current_streak,best_streak,last_played_at) VALUES(?1,?2,?3,?4,?3,?3,?5) ON CONFLICT(player_id,opponent_id) DO UPDATE SET wins=wins+excluded.wins,losses=losses+excluded.losses,current_streak=CASE WHEN excluded.wins=1 THEN current_streak+1 ELSE 0 END,best_streak=MAX(best_streak,CASE WHEN excluded.wins=1 THEN current_streak+1 ELSE 0 END),last_played_at=excluded.last_played_at").bind(id,opp,win,1-win,now)
]); } }
async function getPlayer(env:Env,id:string){ const p=await env.DB.prepare("SELECT * FROM players WHERE id=?1 LIMIT 1").bind(id).first<PlayerRow>(); if(!p) throw new APIError(404,"PLAYER_NOT_FOUND","Pingo player not found"); return p; }
async function getMatch(env:Env,id:string){ const m=await env.DB.prepare("SELECT * FROM matches WHERE id=?1 LIMIT 1").bind(id).first<MatchRow>(); if(!m) throw new APIError(404,"MATCH_NOT_FOUND","Pingo match not found"); if(m.status==="awaitingOpponent"&&m.expires_at<Date.now()){ const now=Date.now(); await env.DB.prepare("UPDATE matches SET status='expired',updated_at=?1 WHERE id=?2 AND status='awaitingOpponent'").bind(now,id).run(); return {...m,status:"expired" as const,updated_at:now}; } return m; }
async function members(env:Env,id:string){ const r=await env.DB.prepare("SELECT player_id FROM match_players WHERE match_id=?1 ORDER BY seat").bind(id).all<{player_id:string}>(); return r.results.map(x=>x.player_id); }
async function member(env:Env,id:string,p:string){ if(!(await env.DB.prepare("SELECT 1 ok FROM match_players WHERE match_id=?1 AND player_id=?2 LIMIT 1").bind(id,p).first())) throw new APIError(403,"NOT_A_MATCH_PLAYER","This player does not belong to the match"); }

function playerJSON(p:PlayerRow){return {id:p.id,username:p.username,avatar:{kind:p.avatar_kind,value:p.avatar_value,background:p.avatar_background},stats:{wins:p.wins,losses:p.losses,draws:p.draws,currentStreak:p.current_streak,bestStreak:p.best_streak},createdAt:p.created_at,updatedAt:p.updated_at};}
function matchJSON(m:MatchRow){return {id:m.id,gameID:m.game_id,status:m.status,revision:m.revision,turnNumber:m.turn_number,createdByPlayerID:m.created_by_player_id,currentPlayerID:m.current_player_id,winnerPlayerID:m.winner_player_id,stateBase64:m.state_base64,createdAt:m.created_at,updatedAt:m.updated_at,expiresAt:m.expires_at};}
function canonical(v:string){const x=v.trim().toLowerCase();if(!USERNAME.test(x))throw new APIError(400,"INVALID_USERNAME","Usernames must be 3-20 lowercase letters, numbers, or underscores");if(RESERVED.has(x))throw new APIError(400,"RESERVED_USERNAME","That username is reserved");return x;}
function avatarOf(v:unknown):Avatar{const a=(v??{kind:"preset",value:"ping",background:"mint"}) as Partial<Avatar>;const backgrounds=new Set(["mint","blue","purple","orange","pink","slate"]),presets=new Set(["ping","orbit","bolt","star","rocket","smile","trophy","wave"]);if((a.kind!=="preset"&&a.kind!=="emoji")||typeof a.value!=="string"||typeof a.background!=="string"||!backgrounds.has(a.background))throw new APIError(400,"INVALID_AVATAR","Invalid avatar");if(a.kind==="preset"&&!presets.has(a.value))throw new APIError(400,"INVALID_AVATAR","Invalid avatar preset");return {kind:a.kind,value:a.kind==="emoji"?Array.from(a.value).slice(0,4).join(""):a.value,background:a.background};}
async function body<T>(r:Request):Promise<T>{if(Number(r.headers.get("content-length")??0)>64_000)throw new APIError(413,"BODY_TOO_LARGE","Request body is too large");try{return await r.json() as T;}catch{throw new APIError(400,"INVALID_JSON","Request body must be valid JSON");}}
function uuid(v:string){if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(v))throw new APIError(400,"INVALID_ID","ID must be a UUID");}
function randomToken(){const b=new Uint8Array(32);crypto.getRandomValues(b);let s="";for(const x of b)s+=String.fromCharCode(x);return btoa(s).replaceAll("+","-").replaceAll("/","_").replaceAll("=","");}
async function sha256(v:string){const d=await crypto.subtle.digest("SHA-256",new TextEncoder().encode(v));return Array.from(new Uint8Array(d),x=>x.toString(16).padStart(2,"0")).join("");}
function decode64(v:string){try{const n=v.replaceAll("-","+").replaceAll("_","/");const s=atob(n+"=".repeat((4-n.length%4)%4));return Uint8Array.from(s,c=>c.charCodeAt(0));}catch{throw new APIError(400,"INVALID_STATE","stateBase64 must be valid base64");}}
function json(v:unknown,status=200){return Response.json(v,{status,headers:{"cache-control":"no-store","x-content-type-options":"nosniff"}});}
