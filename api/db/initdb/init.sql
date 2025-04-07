\connect api;

-- 1. Create the ENUM type for the media field
CREATE TYPE media_type AS ENUM (
    'IMAGE',
    'VIDEO',
    'LINK',
    'TEXT',
    'OTHER'
);

-- 2. Create the Post table
CREATE TABLE posts (
    id         		UUID		    PRIMARY KEY,
    user_id         UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    media		    media_type  	NOT NULL,
    date_created    TIMESTAMPTZ       NOT NULL,
    caption         TEXT
);

CREATE TYPE provider_type as ENUM (
    'FACEBOOK',
    'GOOGLE',
    'APPLE',
    'EMAIL',
    'TWOCENTS'
);

CREATE TABLE users (
	id         		UUID		    PRIMARY KEY,
    firebase_uid    TEXT            UNIQUE NOT NULL,
	provider		provider_type   NOT NULL,
	date_created    TIMESTAMPTZ       NOT NULL,
	username  		TEXT	        NOT NULL,
	hash	        TEXT,
	salt	        TEXT,
    device_tokens   TEXT[]         DEFAULT '{}' NOT NULL 
);

CREATE TABLE user_profiles (
    user_id         UUID            PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    profile_pic     TEXT,
    username        TEXT            NOT NULL,
    name            TEXT
);

CREATE TABLE images (
    id              UUID            PRIMARY KEY,
    post_id         UUID            NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_url  		TEXT            NOT NULL
);

CREATE TABLE videos (
    id              UUID            PRIMARY KEY,
    post_id         UUID            NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_url  		TEXT            NOT NULL
);

CREATE TABLE links (
    id              UUID            PRIMARY KEY,
    post_id         UUID            NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_url  		TEXT            NOT NULL
);

CREATE TABLE texts (
    id              UUID            PRIMARY KEY,
    post_id         UUID            NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    text  		    TEXT            NOT NULL
);

CREATE TYPE friendship_status AS ENUM (
    'PENDING',
    'ACCEPTED',
    'BLOCKED'
);

CREATE TABLE friendships (
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status         friendship_status NOT NULL,
    date_created   TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, friend_id)
);

CREATE TABLE friend_groups (
    id              UUID PRIMARY KEY,
    name            TEXT NOT NULL,
    date_created    TIMESTAMPTZ NOT NULL,
    owner_id        UUID NOT NULL REFERENCES users(id)
    -- Possibly an "owner_id" if you want to track a user who owns/created the group
);

CREATE TYPE group_role AS ENUM (
    'ADMIN',
    'MEMBER'
);

CREATE TABLE friend_group_members (
    group_id UUID NOT NULL REFERENCES friend_groups(id) ON DELETE CASCADE,
    user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL,
    role     group_role NOT NULL,
    PRIMARY KEY (group_id, user_id)
);

CREATE TABLE friend_group_posts (
    group_id UUID NOT NULL REFERENCES friend_groups(id) ON DELETE CASCADE,
    post_id  UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    score   DECIMAL NOT NULL DEFAULT 0,
    PRIMARY KEY (group_id, post_id)
);
