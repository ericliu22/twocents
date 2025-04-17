package media

import (
	"api/internal/core/aws"
	database "api/internal/core/db"
	"context"
	"fmt"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ImageUploader struct {}

func (i ImageUploader) upload(
	queries *database.Queries,
	post *database.Post,
	ctx *gin.Context,
) error {

	fileHeaders, exists := ctx.Request.MultipartForm.File["file"]
	if !exists || len(fileHeaders) == 0 {
		return fmt.Errorf("image upload: no file provided")
	}

	// Open the first file (if more than one file is sent, you can extend this logic)
	file, err := fileHeaders[0].Open()
	if err != nil {
		return fmt.Errorf("image upload: failed to open file: %v", err)
	}
	defer file.Close()

	id := uuid.New()
	filename := fmt.Sprintf("images/%s.jpeg", id.String())
	mediaURL := fmt.Sprintf("https://%s/%s", os.Getenv("CLOUDFRONT_DOMAIN"), filename)

	uploadErr := aws.ObjectUpload(filename, &file, "image/jpeg")

	if uploadErr != nil {
		gin.DefaultWriter.Write([]byte("Failed to upload to S3" + uploadErr.Error()))
		return uploadErr
	}

	imageParams := database.CreateImageParams{
		ID:       id,
		PostID:   post.ID,
		MediaUrl: mediaURL,
	}

	createContext, cancel := context.WithTimeout(context.Background(), 5 * time.Second)
	defer cancel()
	_, createErr := queries.CreateImage(createContext, imageParams)
	if createErr != nil {
		gin.DefaultWriter.Write([]byte("Failed to create image" + createErr.Error()))
		cancel()
		return createErr
	}
	return nil
}
