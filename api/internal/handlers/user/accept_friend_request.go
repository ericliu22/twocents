package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
)

func AcceptFriendRequestHandler(queries *database.Queries) gin.HandlerFunc {
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

		getFriendship := database.GetFriendshipParams{
			UserID:   user.ID,
			FriendID: friendRequest.FriendId,
		}
		friendship, friendshipErr := queries.GetFriendship(ctx.Request.Context(), getFriendship)
		if friendshipErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve friendship")
			gin.DefaultWriter.Write([]byte("Failed to fetch friendship:" + userErr.Error()))
			return
		}
		if friendship.FriendID != user.ID {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}

		updateFriendship := database.UpdateFriendshipStatusParams{
			UserID:   user.ID,
			FriendID: friendRequest.FriendId,
			Status:   database.FriendshipStatusACCEPTED,
		}
		_, acceptErr := queries.UpdateFriendshipStatus(ctx.Request.Context(), updateFriendship)
		if acceptErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to accept friendship")
			gin.DefaultWriter.Write([]byte("Failed to accept friendship:" + acceptErr.Error()))
			return
		}
		ctx.JSON(http.StatusOK, gin.H{"message": "Successfully updated friendship"})
	}
}
