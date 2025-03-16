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

func GetGroupPostsHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// Authentication and user fetching
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

		// Get group ID from query parameters
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

		// Retrieve posts for the group
		postLists, err := queries.ListPostsForGroup(ctx.Request.Context(), groupID)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve posts")
			return
		}

		// Flatten posts if needed
		var posts []database.Post
		for _, post := range postLists {
			posts = append(posts, post.Post)
		}

		// Generate JSON for posts to compute an ETag
		postsJSON, err := json.Marshal(posts)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error generating response")
			return
		}

		if handled := utils.AttachCacheHeaders(ctx, postsJSON, 60); handled {
			return
		}

		// Send the fresh response with posts
		ctx.JSON(http.StatusOK, posts)
	}
}
