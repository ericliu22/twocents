package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type GetUserRequest struct {
	UserId uuid.UUID `form:"userId"`
}

func GetUserHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		_, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}

		var userRequest GetUserRequest
		if bindErr := ctx.Bind(&userRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			return
		}

		userProfile, err := queries.GetUserProfile(ctx.Request.Context(), userRequest.UserId)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve posts")
			return
		}
		ctx.JSON(http.StatusOK, userProfile)
	}
}
