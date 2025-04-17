package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers/user"
	"api/internal/middleware"

	firebaseAuth "firebase.google.com/go/v4/auth"
	"firebase.google.com/go/v4/messaging"
	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(
	router *gin.RouterGroup,
	queries *database.Queries,
	authClient *firebaseAuth.Client,
	messagingClient *messaging.Client,
) {
	r := router.Group("/user", middleware.AuthMiddleware(authClient))
	r.GET("/get-user", handlers.GetUserHandler(queries))
	r.GET("/get-current-user", handlers.GetCurrentUserHandler(queries))
	r.POST("/register-user", handlers.RegisterUserHandler(queries))
	r.POST("/friend-request", handlers.FriendRequestHandler(queries))
	r.POST("/accept-friend-request", handlers.AcceptFriendRequestHandler(queries))
	r.POST("/update-profile-pic", handlers.UpdateProfilePicHandler(queries))
	r.POST("/register-device-token", handlers.RegisterDeviceTokenHandler(queries))
	r.POST("/remove-device-token", handlers.RegisterDeviceTokenHandler(queries))
}
