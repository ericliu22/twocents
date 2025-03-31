package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
)

type RemoveDeviceTokenRequest struct {
	DeviceToken string `json:"deviceToken" binding:"required"`
}

func RemoveDeviceTokenHandler(queries *database.Queries) gin.HandlerFunc {
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

		var removeDeviceTokenRequest RemoveDeviceTokenRequest
		if bindErr := ctx.Bind(&removeDeviceTokenRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			return
		}

		// Prepare the parameters for removing the device token.
		removeToken := database.RemoveDeviceTokenParams{
			ArrayRemove: []string{removeDeviceTokenRequest.DeviceToken},
			ID:          user.ID,
		}

		err := queries.RemoveDeviceToken(ctx.Request.Context(), removeToken)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove device token"})
			return
		}

		ctx.String(http.StatusOK, "Device token removed")
	}
}

