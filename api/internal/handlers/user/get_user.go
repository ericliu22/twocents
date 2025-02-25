package handlers

import (
	"net/http"
	database "api/internal/core/db"
	"github.com/gin-gonic/gin"

)

func GetUserHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		posts, err := queries.GetPosts(ctx.Request.Context())
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve posts")
			return
		}
		ctx.JSON(http.StatusOK, posts)
	}
}
