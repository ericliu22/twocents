-- name: CreateFriendGroup :one
INSERT INTO friend_groups (
    id,
    name,
    date_created,
    owner_id
) VALUES (
    $1, $2, $3, $4
)
RETURNING id, name, date_created, owner_id;

-- name: GetFriendGroup :one
SELECT
    id,
    name,
    date_created,
    owner_id
FROM friend_groups
WHERE id = $1;

-- name: GetFriendGroupsByIDs :many
SELECT
    id,
    name,
    date_created,
    owner_id
FROM friend_groups
WHERE id = ANY($1::uuid[])
ORDER BY name;

-- name: ListFriendGroups :many
SELECT
    id,
    name,
    date_created,
    owner_id
FROM friend_groups;

-- name: UpdateFriendGroupName :one
UPDATE friend_groups
SET name = $2
WHERE id = $1
RETURNING id, name, date_created, owner_id;

-- name: DeleteFriendGroup :exec
DELETE FROM friend_groups
WHERE id = $1;

-- name: AddUserToGroup :one
INSERT INTO friend_group_members (
    group_id,
    user_id,
    joined_at,
    role
) VALUES (
    $1, $2, $3, $4
)
RETURNING group_id, user_id, joined_at, role;

-- name: RemoveUserFromGroup :exec
DELETE FROM friend_group_members
WHERE group_id = $1
  AND user_id = $2;

-- name: ListGroupMembers :many
SELECT
    group_id,
    user_id,
    joined_at,
    role
FROM friend_group_members
WHERE group_id = $1;

-- name: ListUserGroups :many
SELECT sqlc.embed(friend_group_members), sqlc.embed(friend_groups)
FROM friend_group_members
JOIN friend_groups ON friend_group_members.group_id = friend_groups.id
WHERE friend_group_members.user_id = $1;

-- name: CheckUserMembershipForGroups :many
WITH input_groups AS (
    SELECT UNNEST($2::uuid[]) AS group_id
)
SELECT
    ig.group_id::uuid         AS "group_id",
    (fgm.group_id IS NOT NULL)::boolean AS "is_member"
FROM input_groups ig
LEFT JOIN friend_group_members fgm
       ON ig.group_id = fgm.group_id
      AND fgm.user_id = $1
ORDER BY ig.group_id;

