package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers/group"
	"api/internal/middleware"

	firebaseAuth "firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
)

func SetupGroupRoutes(router *gin.RouterGroup, queries *database.Queries, authClient *firebaseAuth.Client) {
	r := router.Group("/group", middleware.AuthMiddleware(authClient))
	r.POST("/create-group", handlers.CreateGroupHandler(queries))
	r.POST("/add-member", handlers.AddMemberHandler(queries))
}
