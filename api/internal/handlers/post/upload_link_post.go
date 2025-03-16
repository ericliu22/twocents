package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Link struct {
	MediaUrl string    `json:"mediaUrl"`
	PostId   uuid.UUID `json:"postId"`
}

func UploadLinkPostHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		_, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}
		var linkRequest Link
		if bindErr := ctx.Bind(&linkRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
			return
		}

		linkParams := database.CreateLinkParams{
			ID:       uuid.New(),
			PostID:   linkRequest.PostId,
			MediaUrl: linkRequest.MediaUrl,
		}

		link, createErr := queries.CreateLink(ctx.Request.Context(), linkParams)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to create video on db")
			gin.DefaultWriter.Write([]byte("Failed to create video" + createErr.Error()))
			return
		}
		ctx.JSON(http.StatusOK, link)
	}
}
