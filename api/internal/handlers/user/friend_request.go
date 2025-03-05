package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type FriendRequest struct {
	FriendId string `json:"friendId"`
}

func FriendRequestHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}

		var friendRequest FriendRequest
		if bindErr := ctx.Bind(&friendRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
			return
		}

		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve user")
			gin.DefaultWriter.Write([]byte("Failed to fetch user:" + userErr.Error()))
			return
		}

		friendUUID, parseErr := uuid.Parse(friendRequest.FriendId)
		if parseErr != nil {
			ctx.String(http.StatusBadRequest, "Error: Failed to parse UUID")
			gin.DefaultWriter.Write([]byte("Failed to parse UUID:" + parseErr.Error()))
			return
		}

		createFriendship := database.CreateFriendshipParams{
			UserID:   user.ID,
			FriendID: friendUUID,
			Status:   database.FriendshipStatusPENDING,
		}
		_, createErr := queries.CreateFriendship(ctx.Request.Context(), createFriendship)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to create friendship")
			gin.DefaultWriter.Write([]byte("Failed to create friendship:" + createErr.Error()))
			return
		}

		ctx.JSON(http.StatusOK, gin.H{"message": "Successfully created friendship"})
	}
}
