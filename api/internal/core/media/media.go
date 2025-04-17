package media

import (
	database "api/internal/core/db"

	"github.com/gin-gonic/gin"
)

type Uploader interface {
	upload(queries *database.Queries, post *database.Post, ctx *gin.Context,) error
}

// getUploader returns the uploader implementation for a given media type.
func getUploader(media database.MediaType) Uploader {
	switch media {
	case database.MediaTypeTEXT:
		return TextUploader{}
	case database.MediaTypeIMAGE:
		return ImageUploader{}
	case database.MediaTypeLINK:
		return LinkUploader{}
	case database.MediaTypeVIDEO:
		return VideoUploader{}
	// Add other cases here, e.g., "VIDEO": VideoUploader{}
	default:
		return nil
	}
}
