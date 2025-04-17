package media

import (
	database "api/internal/core/db"

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

	postStatus := database.UpdatePostStatusParams{
		PostID: post.ID,
	}
	err := uploadMedia(queries, post, ctx)
	if err != nil {
		gin.DefaultWriter.Write([]byte("Failed to upload media: " + err.Error()))
		postStatus.Status = database.PostStatusFAILED
		queries.UpdatePostStatus(ctx, postStatus)
		return err
	}
	postStatus.Status = database.PostStatusPUBLISHED
	queries.UpdatePostStatus(ctx, postStatus)

	incrementErr := queries.IncrementPostCount(ctx.Request.Context(), post.UserID)
	if incrementErr != nil {
		gin.DefaultWriter.Write([]byte("Failed to increment post count: " + incrementErr.Error()))
		postStatus.Status = database.PostStatusFAILED
		queries.UpdatePostStatus(ctx, postStatus)
		return incrementErr
	}
	return nil
}
