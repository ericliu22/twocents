package handlers

import (
	"net/http"

	database "api/internal/core/db"
	"api/internal/middleware"

	"github.com/gin-gonic/gin"
)

func GetPostsHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		_, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}
		posts, err := queries.GetPosts(ctx.Request.Context()) // passing 0 if we’re not using 'id'
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve posts"})
			return
		}
		ctx.JSON(http.StatusOK, posts)
	}
}
