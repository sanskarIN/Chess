abstract final class DatabaseSchema {
  static const int currentVersion = 1;
  static const String fileName = 'chess_master.sqlite3';

  static const List<String> version1Statements = <String>[
    '''
CREATE TABLE app_settings (
  setting_key TEXT NOT NULL PRIMARY KEY,
  value_json TEXT NOT NULL,
  value_type TEXT NOT NULL,
  updated_at INTEGER NOT NULL CHECK (updated_at >= 0)
) WITHOUT ROWID
''',
    '''
CREATE TABLE player_profiles (
  profile_id TEXT NOT NULL PRIMARY KEY,
  display_name TEXT NOT NULL CHECK (length(display_name) BETWEEN 1 AND 40),
  is_default INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0, 1)),
  created_at INTEGER NOT NULL CHECK (created_at >= 0),
  updated_at INTEGER NOT NULL CHECK (updated_at >= created_at)
) WITHOUT ROWID
''',
    '''
CREATE TABLE games (
  game_id TEXT NOT NULL PRIMARY KEY,
  mode TEXT NOT NULL,
  status TEXT NOT NULL,
  initial_fen TEXT NOT NULL,
  current_fen TEXT NOT NULL,
  white_name TEXT NOT NULL,
  black_name TEXT NOT NULL,
  result TEXT,
  result_reason TEXT,
  time_control_json TEXT,
  difficulty TEXT,
  started_at INTEGER NOT NULL CHECK (started_at >= 0),
  completed_at INTEGER,
  updated_at INTEGER NOT NULL CHECK (updated_at >= started_at),
  CHECK (completed_at IS NULL OR completed_at >= started_at)
) WITHOUT ROWID
''',
    '''
CREATE TABLE moves (
  move_id TEXT NOT NULL PRIMARY KEY,
  game_id TEXT NOT NULL,
  ply INTEGER NOT NULL CHECK (ply >= 1),
  from_square TEXT NOT NULL CHECK (length(from_square) = 2),
  to_square TEXT NOT NULL CHECK (length(to_square) = 2),
  promotion TEXT,
  san TEXT NOT NULL,
  fen_after TEXT NOT NULL,
  elapsed_millis INTEGER NOT NULL DEFAULT 0 CHECK (elapsed_millis >= 0),
  created_at INTEGER NOT NULL CHECK (created_at >= 0),
  FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE,
  UNIQUE (game_id, ply)
) WITHOUT ROWID
''',
    '''
CREATE TABLE saved_games (
  saved_game_id TEXT NOT NULL PRIMARY KEY,
  game_id TEXT NOT NULL,
  title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 80),
  notes TEXT,
  created_at INTEGER NOT NULL CHECK (created_at >= 0),
  updated_at INTEGER NOT NULL CHECK (updated_at >= created_at),
  FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE
) WITHOUT ROWID
''',
    '''
CREATE TABLE match_history (
  history_id TEXT NOT NULL PRIMARY KEY,
  game_id TEXT NOT NULL UNIQUE,
  opponent_type TEXT NOT NULL,
  player_color TEXT NOT NULL,
  result TEXT NOT NULL,
  result_reason TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds >= 0),
  move_count INTEGER NOT NULL CHECK (move_count >= 0),
  hint_count INTEGER NOT NULL DEFAULT 0 CHECK (hint_count >= 0),
  completed_at INTEGER NOT NULL CHECK (completed_at >= 0),
  FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE
) WITHOUT ROWID
''',
    '''
CREATE TABLE statistics (
  statistic_key TEXT NOT NULL,
  scope TEXT NOT NULL,
  integer_value INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL CHECK (updated_at >= 0),
  PRIMARY KEY (statistic_key, scope)
) WITHOUT ROWID
''',
    '''
CREATE TABLE daily_challenges (
  challenge_id TEXT NOT NULL PRIMARY KEY,
  local_date TEXT NOT NULL,
  challenge_type TEXT NOT NULL,
  title_key TEXT NOT NULL,
  description_key TEXT NOT NULL,
  target_value INTEGER NOT NULL CHECK (target_value > 0),
  reward_type TEXT NOT NULL,
  reward_amount INTEGER NOT NULL CHECK (reward_amount >= 0),
  difficulty TEXT NOT NULL,
  eligibility_json TEXT NOT NULL,
  definition_version INTEGER NOT NULL CHECK (definition_version >= 1),
  UNIQUE (local_date, challenge_id)
) WITHOUT ROWID
''',
    '''
CREATE TABLE challenge_progress (
  challenge_id TEXT NOT NULL PRIMARY KEY,
  current_value INTEGER NOT NULL DEFAULT 0 CHECK (current_value >= 0),
  completed_at INTEGER,
  claimed_at INTEGER,
  updated_at INTEGER NOT NULL CHECK (updated_at >= 0),
  FOREIGN KEY (challenge_id)
    REFERENCES daily_challenges(challenge_id) ON DELETE CASCADE,
  CHECK (claimed_at IS NULL OR completed_at IS NOT NULL)
) WITHOUT ROWID
''',
    '''
CREATE TABLE reward_transactions (
  transaction_id TEXT NOT NULL PRIMARY KEY,
  transaction_type TEXT NOT NULL,
  asset_type TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount != 0),
  reason_code TEXT NOT NULL,
  source_id TEXT NOT NULL,
  balance_after INTEGER NOT NULL CHECK (balance_after >= 0),
  created_at INTEGER NOT NULL CHECK (created_at >= 0),
  UNIQUE (reason_code, source_id)
) WITHOUT ROWID
''',
    '''
CREATE TABLE achievements (
  achievement_id TEXT NOT NULL PRIMARY KEY,
  progress INTEGER NOT NULL DEFAULT 0 CHECK (progress >= 0),
  target INTEGER NOT NULL CHECK (target > 0),
  unlocked_at INTEGER,
  reward_claimed_at INTEGER,
  definition_version INTEGER NOT NULL CHECK (definition_version >= 1),
  updated_at INTEGER NOT NULL CHECK (updated_at >= 0),
  CHECK (reward_claimed_at IS NULL OR unlocked_at IS NOT NULL)
) WITHOUT ROWID
''',
    '''
CREATE TABLE tutorial_progress (
  lesson_id TEXT NOT NULL PRIMARY KEY,
  attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  completed_at INTEGER,
  reward_claimed_at INTEGER,
  updated_at INTEGER NOT NULL CHECK (updated_at >= 0),
  CHECK (reward_claimed_at IS NULL OR completed_at IS NOT NULL)
) WITHOUT ROWID
''',
    '''
CREATE TABLE recent_opponents (
  opponent_id TEXT NOT NULL PRIMARY KEY,
  display_name TEXT NOT NULL CHECK (length(display_name) BETWEEN 1 AND 40),
  opponent_type TEXT NOT NULL,
  last_played_at INTEGER NOT NULL CHECK (last_played_at >= 0)
) WITHOUT ROWID
''',
    '''
CREATE TABLE developer_preferences (
  preference_key TEXT NOT NULL PRIMARY KEY,
  value_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL CHECK (updated_at >= 0)
) WITHOUT ROWID
''',
    '''
CREATE TABLE data_migrations (
  migration_id TEXT NOT NULL PRIMARY KEY,
  schema_version INTEGER NOT NULL CHECK (schema_version >= 1),
  status TEXT NOT NULL CHECK (status IN ('started', 'completed', 'failed')),
  started_at INTEGER NOT NULL CHECK (started_at >= 0),
  completed_at INTEGER,
  details TEXT,
  CHECK (completed_at IS NULL OR completed_at >= started_at)
) WITHOUT ROWID
''',
    '''
CREATE INDEX idx_games_status_updated_at
ON games(status, updated_at DESC)
''',
    '''
CREATE INDEX idx_moves_game_ply
ON moves(game_id, ply)
''',
    '''
CREATE INDEX idx_match_history_completed_at
ON match_history(completed_at DESC)
''',
    '''
CREATE INDEX idx_match_history_result
ON match_history(result, completed_at DESC)
''',
    '''
CREATE INDEX idx_daily_challenges_local_date
ON daily_challenges(local_date)
''',
    '''
CREATE INDEX idx_reward_transactions_created_at
ON reward_transactions(created_at DESC)
''',
    '''
CREATE INDEX idx_recent_opponents_last_played
ON recent_opponents(last_played_at DESC)
''',
  ];

  static List<String> statementsForUpgrade(int oldVersion, int newVersion) {
    if (oldVersion < 1 || newVersion > currentVersion) {
      throw UnsupportedError(
        'Unsupported database migration from $oldVersion to $newVersion.',
      );
    }
    if (oldVersion >= newVersion) {
      return const <String>[];
    }

    return const <String>[];
  }
}
