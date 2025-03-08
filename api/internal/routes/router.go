package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers"

	firebaseAuth "firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
)

func SetupCoreRouter(router *gin.Engine, queries *database.Queries, authClient *firebaseAuth.Client) {
	router.GET("/", handlers.IndexHandler)
	r := router.Group("/v1")
	SetupUserRoutes(r, queries, authClient)
	SetupPostRoutes(r, queries, authClient)
	SetupGroupRoutes(r, queries, authClient)
}
