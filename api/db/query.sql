-- name: GetPost :one
SELECT * FROM posts
WHERE id = $1 LIMIT 1;

-- name: GetPosts :many
SELECT * FROM posts
ORDER BY date_created;

-- name: CreatePost :one
INSERT INTO posts (
  media, date_created, media_url
) VALUES (
  $1, $2, $3
)
RETURNING *;

-- name: UpdatePost :exec
UPDATE posts
	set media = $2,
	date_created = $3
	media_url = $4,
WHERE id = $1;

-- name: DeletePost :exec
DELETE FROM posts
WHERE id = $1;
