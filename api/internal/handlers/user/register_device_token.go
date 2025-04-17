package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"slices"
)

type RegisterDeviceTokenRequest struct {
	DeviceToken string `json:"deviceToken" binding:"required"`
}

func RegisterDeviceTokenHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			gin.DefaultWriter.Write([]byte("Unauthorized: " + tokenErr.Error()))
			log.Println("Unauthorized: " + tokenErr.Error())
			return
		}

		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user: "+userErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch user: " + userErr.Error()))
			log.Println("Failed to fetch user: " + userErr.Error())
			return
		}

		var registerDeviceTokenRequest RegisterDeviceTokenRequest
		if bindErr := ctx.Bind(&registerDeviceTokenRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
			log.Println("Request body not as specified: " + bindErr.Error())
			return
		}

		if slices.Contains(user.DeviceTokens, registerDeviceTokenRequest.DeviceToken) {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Device token already exists"})
			gin.DefaultWriter.Write([]byte("Device token already exists"))
			log.Println("Device token already exists")
			return
		}
		addToken := database.AddDeviceTokenParams{
			Column1: []string{registerDeviceTokenRequest.DeviceToken},
			ID:      user.ID,
		}
		err := queries.AddDeviceToken(ctx.Request.Context(), addToken)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert device token"})
			log.Println("Failed to insert device token: " + err.Error())
			gin.DefaultWriter.Write([]byte("Failed to insert device token: " + err.Error()))
			return
		}

		ctx.String(http.StatusOK, "Device token added")
	}
}
