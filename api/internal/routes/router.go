package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers"

	"github.com/gin-gonic/gin"
)

func SetupCoreRouter(router *gin.Engine, queries *database.Queries) {
	router.GET("/", handlers.IndexHandler)
	SetupUserRoutes(router)
	SetupPostRoutes(router, queries)
}
