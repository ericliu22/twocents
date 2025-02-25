-- 1. Create a new user with a password
CREATE USER admin WITH PASSWORD '';

-- 2. Create a new database owned by that user
CREATE DATABASE api OWNER admin;

-- 3. (Optional) Grant all privileges on the new DB to the user
GRANT ALL PRIVILEGES ON DATABASE api TO admin;

-- 4. Connect to the new database
\connect api;

-- 5. (Optional) Create extensions, e.g. for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE IF NOT EXISTS media_type AS ENUM (
    'IMAGE',
    'VIDEO',
    'OTHER'
)

CREATE TABLE IF NOT EXISTS posts (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    media      media_type  NOT NULL,
    date       DATE        NOT NULL,
    media_url  TEXT
);
