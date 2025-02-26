package handlers

import (
	database "api/internal/core/db"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type GetUserRequest struct {
	UserId string `form:"userId"`
}

func GetUserHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {

		var userRequest GetUserRequest
		if bindErr := ctx.Bind(&userRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			return
		}

		uuid, parseErr := uuid.Parse(userRequest.UserId)
		if parseErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse as UUID"})
			return
		}

		userProfile, err := queries.GetUserProfile(ctx.Request.Context(), uuid)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve posts")
			return
		}
		ctx.JSON(http.StatusOK, userProfile)
	}
}
