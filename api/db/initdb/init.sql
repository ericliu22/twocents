\connect api;

-- 5. (Optional) Create extensions, e.g. for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE IF NOT EXISTS media_type AS ENUM (
    'IMAGE',
    'VIDEO',
    'OTHER'
)

CREATE TABLE IF NOT EXISTS posts (
    id         UUID        PRIMARY KEY,
    media      media_type  NOT NULL,
    date       DATE        NOT NULL,
    media_url  TEXT
);
