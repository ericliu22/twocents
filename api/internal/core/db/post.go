package database

import (
	"context"
	"api/internal/core/models"
)

const getPosts = `-- name: GetPosts :many
SELECT * FROM posts
ORDER BY date_created;`

func (queries *Queries) GetPosts(ctx context.Context) ([]models.Post, error) {
	rows, err := queries.db.Query(ctx, getPosts)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []models.Post
	for rows.Next() {
		var i models.Post
		if err := rows.Scan(&i.ID, &i.Media, &i.DateCreated, &i.MediaUrl); err != nil {
			return nil, err
		}
		items = append(items, i)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}
