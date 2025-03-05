-- name: CreateFriendship :one
INSERT INTO friendships (
    user_id,
    friend_id,
    status,
    date_created
) VALUES (
    $1, $2, $3, CURRENT_DATE
)
RETURNING user_id, friend_id, status, date_created;

-- name: GetFriendship :one
SELECT
    user_id,
    friend_id,
    status,
    date_created
FROM friendships
WHERE user_id = $1
  AND friend_id = $2;

-- name: UpdateFriendshipStatus :one
UPDATE friendships
SET status = $3
WHERE user_id = $1
  AND friend_id = $2
RETURNING user_id, friend_id, status, date_created;

-- name: ListUserFriendships :many
SELECT
    user_id,
    friend_id,
    status,
    date_created
FROM friendships
WHERE user_id = $1;

-- name: DeleteFriendship :exec
DELETE FROM friendships
WHERE user_id = $1
  AND friend_id = $2;
