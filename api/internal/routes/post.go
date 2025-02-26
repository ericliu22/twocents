package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers/post"
	"api/internal/middleware"

	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
)

func SetupPostRoutes(router *gin.RouterGroup, queries *database.Queries, authClient *auth.Client) {
	r := router.Group("/post", middleware.AuthMiddleware(authClient))
	r.GET("/get-posts", handlers.GetPostsHandler(queries))
}
