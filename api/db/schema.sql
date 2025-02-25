-- 1. Create the ENUM type for the media field
CREATE TYPE media_type AS ENUM (
    'IMAGE',
    'VIDEO',
    'OTHER'
);

-- 2. Create the Post table
CREATE TABLE posts (
    id         		UUID		    PRIMARY KEY,
    media		    media_type  	NOT NULL,
    date_created    DATE        	NOT NULL,
    media_url  		TEXT
);

CREATE TYPE provider_type as ENUM (
    'FACEBOOK',
    'GOOGLE',
    'APPLE',
    'TWOCENTS'
);

CREATE TABLE users (
	id         		UUID		    PRIMARY KEY,
	provider		provider_type      	NOT NULL,
	date_created    DATE        	NOT NULL,
	username  		TEXT	        NOT NULL,
	hash	        TEXT,
	salt	        TEXT
);

