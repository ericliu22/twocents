-- name: GetPost :one
SELECT * FROM posts
WHERE id = $1 LIMIT 1;

-- name: GetPosts :many
SELECT * FROM posts
ORDER BY date_created;

-- name: CreatePost :one
INSERT INTO posts (
    id, user_id, media, date_created, caption
) VALUES (
    $1, $2, $3, $4, $5
)
ON CONFLICT (id) DO NOTHING
RETURNING *;

-- name: UpdatePost :exec
UPDATE posts
SET media = $2,
    date_created = $3,
    caption = $4
WHERE id = $1;

-- name: DeletePost :exec
DELETE FROM posts
WHERE id = $1;

-- name: AddPostToFriendGroup :exec
INSERT INTO friend_group_posts (
    group_id,
    post_id
) VALUES (
    $1, $2
);

-- name: RemovePostFromFriendGroup :exec
DELETE FROM friend_group_posts
WHERE group_id = $1
  AND post_id = $2;

-- name: ListPostsForGroup :many
SELECT sqlc.embed(posts)
FROM friend_group_posts fgp
JOIN posts ON fgp.post_id = posts.id
WHERE fgp.group_id = $1 AND posts.status = 'ACTIVE';

-- name: InitialPostsForGroup :many
SELECT sqlc.embed(posts)
FROM friend_group_posts fgp
JOIN posts ON posts.id = fgp.post_id
WHERE fgp.group_id = $1 AND posts.status = 'ACTIVE'
ORDER BY fgp.score DESC, fgp.post_id DESC
LIMIT $2;

-- name: ListPaginatedPostsForGroup :many
SELECT sqlc.embed(posts)
FROM friend_group_posts fgp
JOIN posts ON posts.id = fgp.post_id
WHERE fgp.group_id = $1
  AND (fgp.score, fgp.post_id) < ($2, $3::uuid)
AND posts.status = 'ACTIVE'
ORDER BY fgp.score DESC, fgp.post_id DESC
LIMIT $4;

-- name: GetPostScore :one
SELECT score
FROM friend_group_posts
WHERE group_id = $1
  AND post_id = $2;

-- name: CheckPostOwner :one
SELECT EXISTS(SELECT 1 FROM posts WHERE user_id = $1 and id = $2);

-- name: CheckUserMemberOfPostGroups :one
SELECT EXISTS (
    SELECT 1
    FROM friend_group_members
    JOIN friend_group_posts ON friend_group_members.group_id = friend_group_posts.group_id
    WHERE friend_group_members.user_id = $1
      AND friend_group_posts.post_id = $2
    LIMIT 1
);

-- name: GetTopPost :one
SELECT sqlc.embed(posts)
FROM friend_group_posts fgp
JOIN posts on fgp.post_id = posts.id
WHERE fgp.group_id = $1 AND fgp.status = 'ACTIVE'
ORDER BY fgp.score DESC
LIMIT 1;

-- name: UpdatePostScore :exec
UPDATE friend_group_posts
SET score = $2
WHERE post_id = $1;

-- name: UpdatePostStatus :exec
UPDATE posts
SET status = $2
WHERE id = $1;
