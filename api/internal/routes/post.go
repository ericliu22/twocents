package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers/post"

	"github.com/gin-gonic/gin"
)

func SetupPostRoutes(router *gin.Engine, queries *database.Queries) {
	router.GET("/v1/post/get-posts", handlers.GetPostsHandler(queries))
}
