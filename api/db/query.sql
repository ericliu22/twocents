-- name: GetPost :one
SELECT * FROM posts
WHERE id = $1 LIMIT 1;

-- name: GetPosts :many
SELECT * FROM posts
ORDER BY date_created;

-- name: CreatePost :one
INSERT INTO posts (
    id, media, date_created, media_url
) VALUES (
    $1, $2, $3, $4
)
RETURNING *;

-- name: UpdatePost :exec
UPDATE posts
    set media = $2,
    date_created = $3,
    media_url = $4
WHERE id = $1;

-- name: DeletePost :exec
DELETE FROM posts
WHERE id = $1;

-- name: GetUser :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetUsers :many
SELECT * FROM users
ORDER BY date_created;

-- name: CreateUser :one
INSERT INTO users (
    id, provider, date_created, username, hash, salt
) VALUES (
    $1, $2, $3, $4, $5, $6
)
RETURNING *;

-- name: UpdateUser :exec
UPDATE users
	set provider = $2,
	date_created = $3,
	username = $4,
    hash = $5,
    salt = $6
WHERE id = $1;

-- name: DeleteUser :exec
DELETE FROM users
WHERE id = $1;
