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

type Text struct {
	PostId uuid.UUID `json:"postId"`
	Text   string    `json:"text"`
}

type TextUploader struct {}

func (t TextUploader) upload(
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
	var textUpload Text
	if err := json.Unmarshal([]byte(jsonData[0]), &textUpload); err != nil {
		return err
	}
	textParams := database.CreateTextParams{
		ID:       uuid.New(),
		PostID:   post.ID,
		Text:	textUpload.Text,
	}

	createContext, cancel := context.WithTimeout(context.Background(), 5 * time.Second)
	defer cancel()
	_, createErr := queries.CreateText(createContext, textParams)
	if createErr != nil {
		gin.DefaultWriter.Write([]byte("Failed to create text" + createErr.Error()))
		cancel()
		return createErr
	}

	return nil
}
