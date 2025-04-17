package routes

import (
	database "api/internal/core/db"
	"api/internal/core/message"
	"api/internal/handlers"

	firebaseAuth "firebase.google.com/go/v4/auth"
	"firebase.google.com/go/v4/messaging"
	"github.com/gin-gonic/gin"
)

func SetupCoreRouter(
	router *gin.Engine,
	queries *database.Queries,
	authClient *firebaseAuth.Client,
	messagingClient *messaging.Client,
	hub *message.Hub,
) {
	router.GET("/", handlers.IndexHandler)
	r := router.Group("/v1")
	SetupUserRoutes(r, queries, authClient, messagingClient)
	SetupPostRoutes(r, queries, authClient, messagingClient)
	SetupGroupRoutes(r, queries, authClient, messagingClient)
	message.SetupKafkaConsumer(hub)
}
