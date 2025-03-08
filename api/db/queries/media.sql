-- name: GetImages :many
SELECT *
FROM images
WHERE post_id = $1;

-- name: CreateImage :one
INSERT INTO images (
    id,
    post_id,
    media_url
)
VALUES ($1, $2, $3)
ON CONFLICT (id) DO NOTHING
RETURNING *;

-- name: GetVideos :many
SELECT *
FROM videos
WHERE post_id = $1;

-- name: CreateVideo :one
INSERT INTO videos (
    id,
    post_id,
    media_url
)
VALUES ($1, $2, $3)
ON CONFLICT (id) DO NOTHING
RETURNING *;

-- name: GetLinks :many
SELECT *
FROM links
WHERE post_id = $1;

-- name: CreateLink :one
INSERT INTO links (
    id,
    post_id,
    media_url
)
VALUES ($1, $2, $3)
ON CONFLICT (id) DO NOTHING
RETURNING *;

-- name: GetTexts :many
SELECT *
FROM texts
WHERE post_id = $1;

-- name: CreateText :one
INSERT INTO texts (
    id,
    post_id,
    text
)
VALUES ($1, $2, $3)
ON CONFLICT (id) DO NOTHING
RETURNING *;
