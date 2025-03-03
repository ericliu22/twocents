-- 1. Create the ENUM type for the media field
CREATE TYPE media_type AS ENUM (
    'IMAGE',
    'VIDEO',
    'LINK',
    'OTHER'
);

-- 2. Create the Post table
CREATE TABLE posts (
    id         		UUID		    PRIMARY KEY,
    user_id         UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    media		    media_type  	NOT NULL,
    date_created    DATE        	NOT NULL,
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
	date_created    DATE            NOT NULL,
	username  		TEXT	        NOT NULL,
	hash	        TEXT,
	salt	        TEXT
);

CREATE TABLE user_profiles (
    user_id         UUID            PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    profile_pic     TEXT,
    username        TEXT            NOT NULL,
    name            TEXT
);

CREATE TABLE images (
    id              UUID            PRIMARY KEY REFERENCES posts(id) on DELETE CASCADE,
    media_url  		TEXT            NOT NULL
);

CREATE TABLE videos (
    id              UUID            PRIMARY KEY REFERENCES posts(id) on DELETE CASCADE,
    media_url       TEXT            NOT NULL
);

CREATE TABLE links (
    id              UUID            PRIMARY KEY REFERENCES posts(id) on DELETE CASCADE,
    media_url       TEXT            NOT NULL
);
