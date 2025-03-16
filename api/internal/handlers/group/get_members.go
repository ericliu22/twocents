package handlers

import (
	database "api/internal/core/db"
	"api/internal/core/utils"
	"api/internal/middleware"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func GetMembersHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
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
		membersList, getErr := queries.ListGroupMembersWithProfiles(ctx.Request.Context(), checkMembership.GroupID)
		if getErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to get members: "+getErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to get members: " + getErr.Error()))
			return
		}
		//DOGSHIT PLEASE FIX
		var members []database.UserProfile
		for _, member := range membersList {
			members = append(members, member.UserProfile)
		}

		membersJson, err := json.Marshal(members)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error generating response")
			return
		}

		if handled := utils.AttachCacheHeaders(ctx, membersJson, 60); handled {
			return
		}

		ctx.JSON(http.StatusOK, members)
	}
}
