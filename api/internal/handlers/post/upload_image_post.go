package handlers

import (
	"api/internal/core/aws"
	database "api/internal/core/db"
	"api/internal/middleware"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
)

func UploadImagePostHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}
		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user")
			return
		}

		postJSON := ctx.PostForm("post")
		if postJSON == "" {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "post part of form is empty"})
			return
		}

		var post database.Post
		if err := json.Unmarshal([]byte(postJSON), &post); err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Error parsing JSON: " + err.Error()})
			return
		}
		if user.ID != post.UserID {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}

		fileHeader, formErr := ctx.FormFile("file")
		if formErr != nil {
			ctx.String(http.StatusBadRequest, "Failed to get form file")
			return
		}
		file, fileErr := fileHeader.Open()
		if fileErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to open file header as file")
			return
		}

		mediaURL, uploadErr := aws.ObjectUpload(post.ID.String(), &file, "image/jpeg")
		if uploadErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to upload image S3"+uploadErr.Error())
			return
		}

		imageParams := database.CreateImageParams{
			ID:       post.ID,
			MediaUrl: *mediaURL,
		}

		image, createErr := queries.CreateImage(ctx.Request.Context(), imageParams)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to create image on db")
			return
		}
		ctx.JSON(http.StatusOK, image)
	}
}
