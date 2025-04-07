-- name: GetUser :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetFirebaseId :one
SELECT * FROM users
WHERE firebase_uid = $1 LIMIT 1;

-- name: CheckFirebaseId :one
SELECT EXISTS(SELECT 1 FROM users WHERE firebase_uid = $1);

-- name: GetUsers :many
SELECT * FROM users
ORDER BY date_created;

-- name: CreateUser :one
INSERT INTO users (
    id, firebase_uid, provider, date_created, username, hash, salt
) VALUES (
    $1, $2, $3, $4, $5, $6, $7
)
ON CONFLICT (id) DO NOTHING
RETURNING *;

-- name: UpdateUser :exec
UPDATE users
SET provider = $2,
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
SET profile_pic = $2,
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

-- name: UpdateProfilePic :exec
UPDATE user_profiles
SET profile_pic = $2
WHERE user_id = $1;

-- name: AddDeviceToken :exec
UPDATE users
SET device_tokens = ARRAY_CAT(device_tokens, $1::TEXT[])
WHERE id = $2;

-- name: RemoveDeviceToken :exec
UPDATE users
SET device_tokens = ARRAY_REMOVE(device_tokens, $1)
WHERE id = $2;

