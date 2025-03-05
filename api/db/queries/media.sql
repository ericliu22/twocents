
-- name: GetImage :one
SELECT *
FROM images
WHERE id = $1;

-- name: CreateImage :one
INSERT INTO images (
    id,
    media_url
)
VALUES ($1, $2)
ON CONFLICT (id) DO NOTHING
RETURNING *;

-- name: GetVideo :one
SELECT *
FROM videos
WHERE id = $1;

-- name: CreateVideo :one
INSERT INTO videos (
    id,
    media_url
)
VALUES ($1, $2)
ON CONFLICT (id) DO NOTHING
RETURNING *;

-- name: GetLink :one
SELECT *
FROM links
WHERE id = $1;

-- name: CreateLink :one
INSERT INTO links (
    id,
    media_url
)
VALUES ($1, $2)
ON CONFLICT (id) DO NOTHING
RETURNING *;
