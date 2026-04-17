-- ╔══════════════════════════════════════════════════════════════╗
-- ║              RAGDO — Initial Supabase Schema                 ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Enable PostGIS for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Users ─────────────────────────────────────────────────────────────────────

CREATE TABLE users (
  id                    TEXT PRIMARY KEY, -- Firebase Auth UID
  phone                 TEXT,
  email                 TEXT,
  name                  TEXT NOT NULL,
  ward_id               TEXT,
  avatar_url            TEXT,
  role                  TEXT NOT NULL DEFAULT 'citizen'
                          CHECK (role IN ('citizen','ward_authority','municipal_authority','state_authority','media_ngo','admin')),
  department            TEXT,
  jurisdiction_wards    TEXT[] DEFAULT '{}',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  karma_score           INT NOT NULL DEFAULT 0,
  issues_filed_count    INT NOT NULL DEFAULT 0,
  issues_resolved_count INT NOT NULL DEFAULT 0,
  fcm_token             TEXT
);

CREATE INDEX users_ward_id_idx ON users(ward_id);
CREATE INDEX users_role_idx ON users(role);

-- ── Issues ────────────────────────────────────────────────────────────────────

CREATE TABLE issues (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title               TEXT NOT NULL CHECK (char_length(title) <= 80),
  description         TEXT NOT NULL CHECK (char_length(description) <= 500),
  category            TEXT NOT NULL CHECK (category IN ('roads','water','garbage','electricity','encroachment','traffic')),
  status              TEXT NOT NULL DEFAULT 'open'
                        CHECK (status IN ('open','in_progress','resolved','rejected')),
  location_lat        DOUBLE PRECISION NOT NULL,
  location_lng        DOUBLE PRECISION NOT NULL,
  location_geog       GEOGRAPHY(Point, 4326),  -- for PostGIS queries
  address_label       TEXT NOT NULL DEFAULT '',
  ward_id             TEXT NOT NULL,
  media_urls          TEXT[] NOT NULL DEFAULT '{}',
  created_by          TEXT NOT NULL REFERENCES users(id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  upvote_count        INT NOT NULL DEFAULT 0,
  downvote_count      INT NOT NULL DEFAULT 0,
  comment_count       INT NOT NULL DEFAULT 0,
  share_count         INT NOT NULL DEFAULT 0,
  view_count          INT NOT NULL DEFAULT 0,
  escalation_tier     TEXT NOT NULL DEFAULT 'ward'
                        CHECK (escalation_tier IN ('ward','municipal','state','media_ngo')),
  escalation_history  JSONB NOT NULL DEFAULT '[]',
  is_resolved         BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_at         TIMESTAMPTZ,
  resolution_note     TEXT,
  assigned_to         TEXT REFERENCES users(id),
  priority_flag       BOOLEAN NOT NULL DEFAULT FALSE
);

-- Auto-update location_geog from lat/lng
CREATE OR REPLACE FUNCTION update_issue_geog()
RETURNS TRIGGER AS $$
BEGIN
  NEW.location_geog = ST_SetSRID(ST_MakePoint(NEW.location_lng, NEW.location_lat), 4326)::geography;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_issue_geog
  BEFORE INSERT OR UPDATE OF location_lat, location_lng ON issues
  FOR EACH ROW EXECUTE FUNCTION update_issue_geog();

CREATE INDEX issues_ward_id_idx ON issues(ward_id);
CREATE INDEX issues_created_at_idx ON issues(created_at DESC);
CREATE INDEX issues_category_idx ON issues(category);
CREATE INDEX issues_escalation_tier_idx ON issues(escalation_tier);
CREATE INDEX issues_status_idx ON issues(status);
CREATE INDEX issues_geog_idx ON issues USING GIST(location_geog);

-- ── View: issues with creator info ───────────────────────────────────────────

CREATE OR REPLACE VIEW issues_with_creators AS
SELECT
  i.*,
  u.name AS created_by_name,
  u.avatar_url AS created_by_avatar
FROM issues i
LEFT JOIN users u ON u.id = i.created_by;

-- ── Votes ─────────────────────────────────────────────────────────────────────

CREATE TABLE votes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id    UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  user_id     TEXT NOT NULL REFERENCES users(id),
  vote_type   TEXT NOT NULL CHECK (vote_type IN ('up','down')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (issue_id, user_id)
);

CREATE INDEX votes_issue_user_idx ON votes(issue_id, user_id);

-- Recompute upvote/downvote counts
CREATE OR REPLACE FUNCTION recompute_vote_counts(p_issue_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE issues
  SET
    upvote_count   = (SELECT COUNT(*) FROM votes WHERE issue_id = p_issue_id AND vote_type = 'up'),
    downvote_count = (SELECT COUNT(*) FROM votes WHERE issue_id = p_issue_id AND vote_type = 'down'),
    updated_at     = NOW()
  WHERE id = p_issue_id;
END;
$$ LANGUAGE plpgsql;

-- ── Bookmarks ─────────────────────────────────────────────────────────────────

CREATE TABLE bookmarks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id    UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  user_id     TEXT NOT NULL REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (issue_id, user_id)
);

CREATE INDEX bookmarks_user_idx ON bookmarks(user_id);

-- ── Comments ──────────────────────────────────────────────────────────────────

CREATE TABLE comments (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id          UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  user_id           TEXT NOT NULL REFERENCES users(id),
  text              TEXT NOT NULL CHECK (char_length(text) <= 300),
  media_url         TEXT,
  parent_comment_id UUID REFERENCES comments(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  upvote_count      INT NOT NULL DEFAULT 0
);

CREATE INDEX comments_issue_idx ON comments(issue_id);
CREATE INDEX comments_parent_idx ON comments(parent_comment_id);

-- View: comments with user info
CREATE OR REPLACE VIEW comments_with_users AS
SELECT
  c.*,
  u.name AS user_name,
  u.avatar_url AS user_avatar
FROM comments c
LEFT JOIN users u ON u.id = c.user_id;

-- ── Authority Actions ─────────────────────────────────────────────────────────

CREATE TABLE authority_actions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  issue_id      UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  authority_id  TEXT NOT NULL REFERENCES users(id),
  action_type   TEXT NOT NULL
                  CHECK (action_type IN ('acknowledged','in_progress','resolved','rejected','escalated','comment')),
  note          TEXT,
  media_url     TEXT,
  is_internal   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX authority_actions_issue_idx ON authority_actions(issue_id);

-- View: authority_actions with authority user info
CREATE OR REPLACE VIEW authority_actions_with_users AS
SELECT
  aa.*,
  u.name AS authority_name,
  u.department AS authority_department,
  u.ward_id AS authority_ward
FROM authority_actions aa
LEFT JOIN users u ON u.id = aa.authority_id;

-- ── Notifications ─────────────────────────────────────────────────────────────

CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     TEXT NOT NULL REFERENCES users(id),
  type        TEXT NOT NULL, -- 'upvote'|'comment'|'reply'|'escalation'|'authority_response'|'new_ward_issue'|'assignment'|'escalated_to_tier'
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  issue_id    UUID REFERENCES issues(id) ON DELETE CASCADE,
  actor_id    TEXT REFERENCES users(id),
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX notifications_user_idx ON notifications(user_id, created_at DESC);

-- ── Helper Functions ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION increment_view_count(issue_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE issues SET view_count = view_count + 1 WHERE id = issue_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_comment_count(issue_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE issues SET comment_count = comment_count + 1 WHERE id = issue_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_issues_filed(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET issues_filed_count = issues_filed_count + 1 WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_comment_upvote(comment_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE comments SET upvote_count = upvote_count + 1 WHERE id = comment_id;
END;
$$ LANGUAGE plpgsql;

-- Ward stats for authority dashboard
CREATE OR REPLACE FUNCTION get_ward_stats(p_ward_id TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'open_count',        COUNT(*) FILTER (WHERE status = 'open'),
    'in_progress_count', COUNT(*) FILTER (WHERE status = 'in_progress'),
    'resolved_count',    COUNT(*) FILTER (WHERE status = 'resolved'),
    'rejected_count',    COUNT(*) FILTER (WHERE status = 'rejected'),
    'avg_resolution_days', COALESCE(
      ROUND(AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 86400)
        FILTER (WHERE is_resolved = TRUE)::NUMERIC, 1),
      0
    ),
    'escalated_count',   COUNT(*) FILTER (WHERE escalation_tier != 'ward'),
    'total_count',       COUNT(*),
    'by_category', (
      SELECT json_object_agg(category, cnt)
      FROM (
        SELECT category, COUNT(*) as cnt
        FROM issues WHERE ward_id = p_ward_id
        GROUP BY category
      ) cats
    ),
    'oldest_open_id', (
      SELECT id FROM issues
      WHERE ward_id = p_ward_id AND is_resolved = FALSE AND status != 'rejected'
      ORDER BY created_at ASC LIMIT 1
    )
  )
  INTO result
  FROM issues
  WHERE ward_id = p_ward_id;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Nearby issues within 2km (PostGIS)
CREATE OR REPLACE FUNCTION get_nearby_issues(p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION, p_radius_m FLOAT DEFAULT 2000)
RETURNS SETOF issues_with_creators AS $$
BEGIN
  RETURN QUERY
  SELECT ic.*
  FROM issues_with_creators ic
  JOIN issues i ON i.id = ic.id
  WHERE ST_DWithin(
    i.location_geog,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
    p_radius_m
  )
  ORDER BY ic.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ── Row Level Security (RLS) ──────────────────────────────────────────────────

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE authority_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users: anyone can read, own row write
CREATE POLICY "users_read_all" ON users FOR SELECT USING (true);
CREATE POLICY "users_write_own" ON users FOR ALL USING (auth.uid()::text = id);

-- Issues: anyone can read, authenticated can insert, creator can update
CREATE POLICY "issues_read_all" ON issues FOR SELECT USING (true);
CREATE POLICY "issues_insert_auth" ON issues FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "issues_update_creator" ON issues FOR UPDATE USING (auth.uid()::text = created_by);

-- Votes: authenticated only
CREATE POLICY "votes_read_all" ON votes FOR SELECT USING (true);
CREATE POLICY "votes_own" ON votes FOR ALL USING (auth.uid()::text = user_id);

-- Bookmarks: own only
CREATE POLICY "bookmarks_own" ON bookmarks FOR ALL USING (auth.uid()::text = user_id);

-- Comments: read all, write authenticated
CREATE POLICY "comments_read_all" ON comments FOR SELECT USING (true);
CREATE POLICY "comments_insert_auth" ON comments FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Authority actions: read public non-internal, authority writes
CREATE POLICY "authority_actions_read_public" ON authority_actions
  FOR SELECT USING (is_internal = FALSE OR auth.uid()::text IN (
    SELECT id FROM users WHERE role != 'citizen'
  ));
CREATE POLICY "authority_actions_insert" ON authority_actions
  FOR INSERT WITH CHECK (auth.uid()::text IN (
    SELECT id FROM users WHERE role != 'citizen'
  ));

-- Notifications: own only
CREATE POLICY "notifications_own" ON notifications FOR ALL USING (auth.uid()::text = user_id);
