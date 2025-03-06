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
	r.GET("/get-group-posts", handlers.GetGroupPostsHandler(queries))
	r.GET("/get-media", handlers.GetMediaHandler(queries))
	r.POST("/create-post", handlers.CreatePostHandler(queries))
	r.POST("/upload-image-post", handlers.UploadImagePostHandler(queries))
	r.POST("/upload-video-post", handlers.UploadVideoPostHandler(queries))
	r.POST("/upload-link-post", handlers.UploadLinkPostHandler(queries))
}
