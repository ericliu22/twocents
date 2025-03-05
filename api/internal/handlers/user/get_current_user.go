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

		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve user")
			return
		}
		userProfile, profileErr := queries.GetUserProfile(ctx.Request.Context(), user.ID)
		if profileErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve user profile")
			return
		}
		ctx.JSON(http.StatusOK, userProfile)
	}
}
