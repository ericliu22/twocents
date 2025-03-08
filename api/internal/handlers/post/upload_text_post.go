package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Text struct {
	Text string `json:"text"`
}

func UploadTextPostHandler(queries *database.Queries) gin.HandlerFunc {
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

		textJSON := ctx.PostForm("text")
		if textJSON == "" {
			ctx.String(http.StatusBadRequest, "Failed to get form text")
			gin.DefaultWriter.Write([]byte("Text form is empty"))
			return
		}

		var textRequest Text
		if err := json.Unmarshal([]byte(postJSON), &textRequest); err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Error parsing JSON: " + err.Error()})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + err.Error()))
			return
		}

		textParams := database.CreateTextParams {
			ID:       uuid.New(),
			PostID:	  post.ID,
			Text: textRequest.Text,
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
