\connect api;

-- 5. (Optional) Create extensions, e.g. for UUID generation
CREATE TYPE IF EXISTS media_type AS ENUM (
    'IMAGE',
    'VIDEO',
    'OTHER'
)

CREATE TABLE IF EXISTS posts (
    id                  UUID        PRIMARY KEY,
    media               media_type  NOT NULL,
    date_created        DATE        NOT NULL,
    media_url           TEXT
);

CREATE TYPE IF EXISTS provider_type as ENUM (
    'FACEBOOK',
    'GOOGLE',
    'APPLE',
    'EMAIL',
    'TWOCENTS'
);

CREATE TABLE IF EXISTS users (
	id         		UUID		    PRIMARY KEY,
	provider		provider_type   NOT NULL,
	date_created    DATE        	NOT NULL,
	username  		TEXT	        NOT NULL,
	hash	        TEXT,
	salt	        TEXT
);

CREATE TABLE IF EXISTS user_profiles (
    user_id         UUID            PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    profile_pic     TEXT,
    username        TEXT            NOT NULL,
    name            TEXT
);
