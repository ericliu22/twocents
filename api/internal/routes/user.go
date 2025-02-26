package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers/user"
	"api/internal/middleware"

	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(router *gin.RouterGroup, queries *database.Queries, authClient *auth.Client) {
	r := router.Group("/user", middleware.FirebaseAuthMiddleware(authClient))
	r.GET("/get-user", handlers.GetUserHandler(queries))
	r.POST("/register-user", handlers.GetUserHandler(queries))
}
