package media

import (
	database "api/internal/core/db"
	"context"
	"time"

	"github.com/gin-gonic/gin"
)

func uploadMedia(queries *database.Queries, post *database.Post, ctx *gin.Context) error {
	uploader := getUploader(post.Media)
	uploadErr := uploader.upload(queries, post, ctx)
	if uploadErr != nil {
		gin.DefaultWriter.Write([]byte("Failed to upload media: " + uploadErr.Error()))
		return uploadErr
	}
	return nil
}

func CreateMedia(queries *database.Queries, post *database.Post, ctx *gin.Context) error {

	createContext, cancel := context.WithTimeout(context.Background(), 5 * time.Second)
	defer cancel()
	postStatus := database.UpdatePostStatusParams{
		ID: post.ID,
	}
	err := uploadMedia(queries, post, ctx)
	if err != nil {
		gin.DefaultWriter.Write([]byte("Failed to upload media: " + err.Error() + "\n"))
		postStatus.Status = database.PostStatusFAILED
		queries.UpdatePostStatus(context.Background(), postStatus)
		cancel()
		return err
	}
	postStatus.Status = database.PostStatusPUBLISHED
	updateErr := queries.UpdatePostStatus(createContext, postStatus)
	if updateErr != nil {
		gin.DefaultWriter.Write([]byte("Failed to update post status: " + updateErr.Error() + "\n"))
	}

	incrementErr := queries.IncrementPostCount(createContext, post.UserID)
	if incrementErr != nil {
		gin.DefaultWriter.Write([]byte("Failed to increment post count: " + incrementErr.Error() + "\n"))
		postStatus.Status = database.PostStatusFAILED
		queries.UpdatePostStatus(context.Background(), postStatus)
		cancel()
		return incrementErr
	}
	return nil
}
