package fetch

import (
	database "api/internal/core/db"
	"context"
)

func FetchMedia(ctx context.Context, queries *database.Queries, post database.Post) any {
	var media any
	switch post.Media {
	case database.MediaTypeIMAGE:
		media, _ = queries.GetImages(ctx, post.ID)
	case database.MediaTypeVIDEO:
		media, _ = queries.GetVideos(ctx, post.ID)
	case database.MediaTypeLINK:
		media, _ = queries.GetLinks(ctx, post.ID)
	case database.MediaTypeTEXT:
		media, _ = queries.GetTexts(ctx, post.ID)
	}
	return media
}
