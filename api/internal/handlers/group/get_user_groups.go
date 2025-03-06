package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetUserGroupsHandler(queries *database.Queries) gin.HandlerFunc {
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

		userGroups, groupErr := queries.ListUserGroups(ctx.Request.Context(), user.ID)
		if groupErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch groups: "+groupErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch groups: " + groupErr.Error()))
		}

		//DOGSHIT PLEASE FIX
		var groups []database.FriendGroup
		for _, group := range userGroups {
			groups = append(groups, group.FriendGroup)
		}
		ctx.JSON(http.StatusOK, groups)
	}
}
