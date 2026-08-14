PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS player_progression (
  player_id TEXT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  state_json TEXT NOT NULL DEFAULT '{}',
  updated_at INTEGER NOT NULL
);

-- Reserved for the final Apple/App Store setup. Only server-verified transactions
-- may write this table; Wave 5 exposes no client endpoint that can grant purchases.
CREATE TABLE IF NOT EXISTS store_entitlements (
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  transaction_id TEXT NOT NULL UNIQUE,
  original_transaction_id TEXT,
  purchased_at INTEGER NOT NULL,
  revoked_at INTEGER,
  environment TEXT,
  verified_at INTEGER NOT NULL,
  PRIMARY KEY (player_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_store_entitlements_player ON store_entitlements(player_id);
