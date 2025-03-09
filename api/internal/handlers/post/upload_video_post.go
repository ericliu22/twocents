package handlers

import (
	"api/internal/core/aws"
	database "api/internal/core/db"
	"api/internal/middleware"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func UploadVideoPostHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}
		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user")
			gin.DefaultWriter.Write([]byte("Failed to fetch user" + userErr.Error()))
			return
		}

		postJSON := ctx.PostForm("post")
		if postJSON == "" {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "post part of form is empty"})
			gin.DefaultWriter.Write([]byte("Post form is empty"))
			return
		}

		var post database.Post
		if err := json.Unmarshal([]byte(postJSON), &post); err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Error parsing JSON: " + err.Error()})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + err.Error()))
			return
		}
		if user.ID != post.UserID {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}

		fileHeader, formErr := ctx.FormFile("file")
		if formErr != nil {
			ctx.String(http.StatusBadRequest, "Failed to get form file")
			gin.DefaultWriter.Write([]byte("File form is empty"))
			return
		}
		file, fileErr := fileHeader.Open()
		if fileErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to open file header as file")
			gin.DefaultWriter.Write([]byte("Failed to open file header as file" + fileErr.Error()))
			return
		}

		id := uuid.New()
		mediaURL, uploadErr := aws.ObjectUpload("videos/" + id.String()+".mp4", &file, "video/mp4")
		if uploadErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to upload video to S3"+uploadErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to upload to S3" + uploadErr.Error()))
			return
		}

		videoParams := database.CreateVideoParams{
			ID:       id,
			PostID:	  post.ID,
			MediaUrl: *mediaURL,
		}

		video, createErr := queries.CreateVideo(ctx.Request.Context(), videoParams)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to create video on db")
			gin.DefaultWriter.Write([]byte("Failed to create video" + createErr.Error()))
			return
		}
		ctx.JSON(http.StatusOK, video)
	}
}
