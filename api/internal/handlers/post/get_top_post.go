package handlers

import (
	database "api/internal/core/db"
	"api/internal/core/fetch"
	"api/internal/core/utils"
	"api/internal/middleware"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func GetTopPostHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}
		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user: "+userErr.Error())
			return
		}
		groupIDStr := ctx.Query("groupId")
		if groupIDStr == "" {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "groupId is required"})
			return
		}
		groupID, err := uuid.Parse(groupIDStr)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid groupId"})
			return
		}

		// Check membership
		checkMembership := database.CheckUserMembershipParams{
			GroupID: groupID,
			UserID:  user.ID,
		}
		isMember, checkErr := queries.CheckUserMembership(ctx.Request.Context(), checkMembership)
		if checkErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to check membership: "+checkErr.Error())
			return
		}
		if !isMember {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}
		postRow, fetchErr := queries.GetTopPost(ctx.Request.Context(), groupID) 
		if fetchErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch post: "+fetchErr.Error())
			return
		}
		media := fetch.FetchMedia(ctx.Request.Context(), queries, postRow.Post)

		response := PostWithMedia {
			Post:  postRow.Post,
			Media: media,
		}

		responseJSON, err := json.Marshal(response)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error generating response")
			return
		}

		if handled := utils.AttachCacheHeaders(ctx, responseJSON, 600); handled {
			return
		}
		
		ctx.JSON(http.StatusOK, response)
	}
}
