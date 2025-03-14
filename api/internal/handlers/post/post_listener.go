package handlers

import (
	database "api/internal/core/db"
	"api/internal/core/message"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func PostListenerHandler(queries *database.Queries, hub *message.Hub) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// Extract the target user ID from the URL parameters.
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}
		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user: "+userErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch user: " + userErr.Error()))
			return
		}

		groupIDStr := ctx.Query("groupId")
		if groupIDStr == "" {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "groupId is required"})
			gin.DefaultWriter.Write([]byte("Failed to query groupId"))
			return
		}

		groupID, err := uuid.Parse(groupIDStr)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid groupId"})
			gin.DefaultWriter.Write([]byte("Failed to parse groupId"))
			return
		}
		checkMembership := database.CheckUserMembershipParams{
			GroupID: groupID,
			UserID:  user.ID,
		}
		isMember, checkErr := queries.CheckUserMembership(ctx.Request.Context(), checkMembership)
		if checkErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to check membership: "+checkErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to check membership: " + checkErr.Error()))
			return
		}
		if !isMember {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}

		// Upgrade the HTTP connection to a WebSocket.
		// This registers the client with the Hub and starts its read/write pumps.
		message.ServeWS(hub, ctx.Writer, ctx.Request, groupID)
	}
}
