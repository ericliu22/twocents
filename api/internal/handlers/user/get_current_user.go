package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetCurrentUserHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}

		userProfile, err := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve user")
			return
		}
		ctx.JSON(http.StatusOK, userProfile)
	}
}
