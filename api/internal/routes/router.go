package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers"

	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
)

func SetupCoreRouter(router *gin.Engine, queries *database.Queries, authClient *auth.Client) {
	router.GET("/", handlers.IndexHandler)
	r := router.Group("/v1")
	SetupUserRoutes(r, queries, authClient)
	SetupPostRoutes(r, queries, authClient)
}
