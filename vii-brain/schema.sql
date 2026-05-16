-- vii-brain schema. Applied automatically by vii-brain.mjs on first run.

CREATE TABLE IF NOT EXISTS entries (
    id         BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    project    TEXT NOT NULL DEFAULT '',
    tag        TEXT NOT NULL,
    body       TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS entries_project_tag ON entries (project, tag);
CREATE INDEX IF NOT EXISTS entries_created     ON entries (created_at DESC);
