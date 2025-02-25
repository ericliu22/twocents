-- 1. Create the ENUM type for the media field
CREATE TYPE media_type AS ENUM (
    'IMAGE',
    'VIDEO',
    'OTHER'
);

-- 2. Create the Post table
CREATE TABLE posts (
    id         		UUID		PRIMARY KEY,
    media		media_type  	NOT NULL,
    date_created     	DATE        	NOT NULL,
    media_url  		TEXT
);

