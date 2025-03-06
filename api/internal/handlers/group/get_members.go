package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type GetMembersRequest struct {
	GroupId uuid.UUID `form:"groupId"`
}

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
		
		var getRequest GetMembersRequest
		if bindErr := ctx.Bind(&getRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			return
		}

		checkMembership := database.CheckUserMembershipParams {
			GroupID: getRequest.GroupId,
			UserID: user.ID,
		}
		isMember, checkErr := queries.CheckUserMembership(ctx.Request.Context(), checkMembership)
		if checkErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to check membership: " + checkErr.Error())
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
			ctx.String(http.StatusInternalServerError, "Failed to get members: " + getErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to get members: " + getErr.Error()))
			return
		}

		ctx.JSON(http.StatusOK, membersList)
	}
}
