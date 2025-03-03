package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type GetPostRequest struct {
	PostId string `form:"postId"`
}

func GetPostHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		_, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}

		var postRequest GetPostRequest
		if bindErr := ctx.Bind(&postRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			return
		}

		uuid, parseErr := uuid.Parse(postRequest.PostId)
		if parseErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse as UUID"})
			return
		}

		post, err := queries.GetPost(ctx.Request.Context(), uuid)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve posts")
			return
		}
		ctx.JSON(http.StatusOK, post)
	}
}
