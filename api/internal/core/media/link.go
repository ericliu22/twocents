package media

import (
	database "api/internal/core/db"
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type LinkUploader struct {}

type Link struct {
	MediaUrl string    `json:"mediaUrl"`
}

func (l LinkUploader) upload(
	queries *database.Queries,
	post *database.Post,
	ctx *gin.Context,
) error {

	jsonData, exists := ctx.Request.MultipartForm.Value["data"]
	if !exists || len(jsonData) == 0 {
		return fmt.Errorf("link upload: no link provided")
	}
		// You might have a specific structure for the additional JSON.
		// For this example, we'll assume it's a generic map.
	var linkUpload Link
	if err := json.Unmarshal([]byte(jsonData[0]), &linkUpload); err != nil {
		return err
	}
	linkParams := database.CreateLinkParams{
		ID:       uuid.New(),
		PostID:   post.ID,
		MediaUrl: linkUpload.MediaUrl,
	}

	createContext, cancel := context.WithTimeout(context.Background(), 5 * time.Second)
	defer cancel()
	_, createErr := queries.CreateLink(createContext, linkParams)
	if createErr != nil {
		gin.DefaultWriter.Write([]byte("Failed to create link" + createErr.Error()))
		cancel()
		return createErr
	}

	return nil
}
