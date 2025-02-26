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
ON CONFLICT (id) DO NOTHING
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
ON CONFLICT (id) DO NOTHING
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

-- name: CheckUser :one
SELECT EXISTS(SELECT 1 FROM users WHERE id = $1);

-- name: CreateUserProfile :one
INSERT INTO user_profiles (
    user_id,
    profile_pic,
    username,
    name
)
VALUES ($1, $2, $3, $4)
ON CONFLICT (user_id) DO NOTHING
RETURNING *;

-- name: GetUserProfile :one
SELECT *
FROM user_profiles
WHERE user_id = $1;

-- name: UpdateUserProfile :exec
UPDATE user_profiles
SET
    profile_pic = $2,
    username    = $3,
    name        = $4
WHERE user_id = $1;

-- name: DeleteUserProfile :exec
DELETE FROM user_profiles
WHERE user_id = $1;


-- name: GetEntireUser :one
SELECT sqlc.embed(users), sqlc.embed(user_profiles)
FROM users
JOIN user_profiles ON users.id = user_profiles.user_id
WHERE users.id = $1;
