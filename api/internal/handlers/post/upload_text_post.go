package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Text struct {
	PostId uuid.UUID `json:"postId"`
	Text string `json:"text"`
}

func UploadTextPostHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		_, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}
		var textRequest Text
		if bindErr := ctx.Bind(&textRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
			return
		}
		textParams := database.CreateTextParams{
			ID:     uuid.New(),
			PostID: textRequest.PostId,
			Text:   textRequest.Text,
		}

		text, createErr := queries.CreateText(ctx.Request.Context(), textParams)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to create text")
			gin.DefaultWriter.Write([]byte("Failed to create text" + createErr.Error()))
			return
		}
		ctx.JSON(http.StatusOK, text)
	}
}
