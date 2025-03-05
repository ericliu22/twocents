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
FROM friend_group_posts
JOIN posts ON friend_group_posts.post_id = posts.id
WHERE friend_group_posts.group_id = $1;

-- name: CheckPostOwner :one
SELECT EXISTS(SELECT 1 FROM posts WHERE user_id = $1 and id = $2);
