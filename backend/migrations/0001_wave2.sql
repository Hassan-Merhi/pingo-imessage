PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS players (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL COLLATE NOCASE UNIQUE,
  avatar_kind TEXT NOT NULL CHECK (avatar_kind IN ('preset', 'emoji')),
  avatar_value TEXT NOT NULL,
  avatar_background TEXT NOT NULL,
  wins INTEGER NOT NULL DEFAULT 0 CHECK (wins >= 0),
  losses INTEGER NOT NULL DEFAULT 0 CHECK (losses >= 0),
  draws INTEGER NOT NULL DEFAULT 0 CHECK (draws >= 0),
  current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
  best_streak INTEGER NOT NULL DEFAULT 0 CHECK (best_streak >= 0),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS device_tokens (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  last_used_at INTEGER NOT NULL,
  revoked_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_device_tokens_player ON device_tokens(player_id);

CREATE TABLE IF NOT EXISTS matches (
  id TEXT PRIMARY KEY,
  game_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('awaitingOpponent', 'active', 'completed', 'resigned', 'expired')),
  revision INTEGER NOT NULL DEFAULT 0 CHECK (revision >= 0),
  turn_number INTEGER NOT NULL DEFAULT 0 CHECK (turn_number >= 0),
  created_by_player_id TEXT NOT NULL REFERENCES players(id),
  current_player_id TEXT REFERENCES players(id),
  winner_player_id TEXT REFERENCES players(id),
  state_base64 TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  rematch_of_match_id TEXT REFERENCES matches(id)
);
CREATE INDEX IF NOT EXISTS idx_matches_updated ON matches(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status, expires_at);

CREATE TABLE IF NOT EXISTS match_players (
  match_id TEXT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  seat INTEGER NOT NULL CHECK (seat IN (0, 1)),
  joined_at INTEGER NOT NULL,
  PRIMARY KEY (match_id, player_id),
  UNIQUE (match_id, seat)
);
CREATE INDEX IF NOT EXISTS idx_match_players_player ON match_players(player_id, match_id);

CREATE TABLE IF NOT EXISTS match_events (
  id TEXT PRIMARY KEY,
  match_id TEXT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  revision INTEGER NOT NULL,
  actor_player_id TEXT REFERENCES players(id),
  kind TEXT NOT NULL,
  payload_json TEXT NOT NULL DEFAULT '{}',
  created_at INTEGER NOT NULL,
  UNIQUE (match_id, revision)
);

CREATE TABLE IF NOT EXISTS game_stats (
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  game_id TEXT NOT NULL,
  wins INTEGER NOT NULL DEFAULT 0,
  losses INTEGER NOT NULL DEFAULT 0,
  draws INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  best_streak INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (player_id, game_id)
);

CREATE TABLE IF NOT EXISTS opponent_records (
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  opponent_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  wins INTEGER NOT NULL DEFAULT 0,
  losses INTEGER NOT NULL DEFAULT 0,
  draws INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  best_streak INTEGER NOT NULL DEFAULT 0,
  last_played_at INTEGER,
  PRIMARY KEY (player_id, opponent_id),
  CHECK (player_id <> opponent_id)
);
