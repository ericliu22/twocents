package routes

import (
	database "api/internal/core/db"
	"api/internal/handlers"

	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(router *gin.Engine, queries *database.Queries) {
	router.GET("/v1/user/get-user", handlers.GetUserHandler(queries))
}
