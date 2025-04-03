package handlers

import (
	database "api/internal/core/db"
	"api/internal/core/utils"
	"api/internal/middleware"
	"encoding/json"
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
			ctx.String(http.StatusInternalServerError, "Failed to fetch user: "+userErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch user: " + userErr.Error()))
			return
		}
		userProfile, profileErr := queries.GetUserProfile(ctx.Request.Context(), user.ID)
		if profileErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve user profile")
			gin.DefaultWriter.Write([]byte("Failed to retrieve user profile: " + profileErr.Error()))
			return
		}

		userJson, err := json.Marshal(userProfile)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error generating response")
			return
		}

		if handled := utils.AttachCacheHeaders(ctx, userJson, 600); handled {
			return
		}

		ctx.JSON(http.StatusOK, userProfile)
	}
}
