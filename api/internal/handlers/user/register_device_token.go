package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
)

type RegisterDeviceTokenRequest struct {
	DeviceToken string `json:"device_token" binding:"required"`
}

func RegisterDeviceTokenHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			return
		}

		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user: "+userErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch user: " + userErr.Error()))
			return
		}

		var registerDeviceTokenRequest RegisterDeviceTokenRequest
		if bindErr := ctx.Bind(&registerDeviceTokenRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			return
		}

		addToken := database.AddDeviceTokenParams{
			ArrayAppend: []string{registerDeviceTokenRequest.DeviceToken},
			ID:          user.ID,
		}
		err := queries.AddDeviceToken(ctx.Request.Context(), addToken)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert device token"})
			return
		}

		ctx.String(http.StatusOK, "Device token added")
	}
}
