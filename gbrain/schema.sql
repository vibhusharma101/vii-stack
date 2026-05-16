-- GBrain schema. Targets PGLite (default) and Supabase Postgres (opt-in).
-- Wired up in Phase 6.

CREATE TABLE IF NOT EXISTS entries (
    id          BIGSERIAL PRIMARY KEY,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    project     TEXT NOT NULL,
    tag         TEXT NOT NULL,
    body        TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS entries_project_tag_idx ON entries (project, tag);
CREATE INDEX IF NOT EXISTS entries_created_idx      ON entries (created_at DESC);

-- Full-text search (Postgres tsvector). PGLite supports tsvector as of 0.2+.
ALTER TABLE entries
    ADD COLUMN IF NOT EXISTS body_tsv tsvector
        GENERATED ALWAYS AS (to_tsvector('english', coalesce(body, ''))) STORED;

CREATE INDEX IF NOT EXISTS entries_body_tsv_idx ON entries USING GIN (body_tsv);

-- Per-project trust tier for remote GBrain sync (Supabase mode).
CREATE TABLE IF NOT EXISTS project_trust (
    project   TEXT PRIMARY KEY,
    tier      TEXT NOT NULL CHECK (tier IN ('read-write','read-only','deny')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
