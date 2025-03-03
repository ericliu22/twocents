package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers/post"
	"api/internal/middleware"

	firebaseAuth "firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
)

func SetupPostRoutes(router *gin.RouterGroup, queries *database.Queries, authClient *firebaseAuth.Client) {
	r := router.Group("/post", middleware.AuthMiddleware(authClient))
	r.GET("/get-posts", handlers.GetPostsHandler(queries))
	r.GET("/get-post", handlers.GetPostHandler(queries))
	r.POST("/create-post", handlers.CreatePostHandler(queries))
	r.POST("/upload-image-post", handlers.UploadImagePostHandler(queries))
}
