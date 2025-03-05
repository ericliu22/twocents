package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AddPostRequest struct {
	PostId uuid.UUID   `json:"postId"`
	Groups []uuid.UUID `json:"groups"`
}

func AddPostHandler(queries *database.Queries) gin.HandlerFunc {
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

		var addRequest AddPostRequest
		if bindErr := ctx.Bind(&addRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			return
		}

		checkPost := database.CheckPostOwnerParams{
			UserID: user.ID,
			ID:     addRequest.PostId,
		}

		isOwner, checkErr := queries.CheckPostOwner(ctx.Request.Context(), checkPost)
		if checkErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to post ownership: "+checkErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch user" + checkErr.Error()))
			return
		}

		if !isOwner {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}

		checkMembership := database.CheckUserMembershipForGroupsParams{
			UserID:  user.ID,
			Column2: addRequest.Groups,
		}
		memberships, checkErr := queries.CheckUserMembershipForGroups(ctx.Request.Context(), checkMembership)
		if checkErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to check membership: "+checkErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to check membership: " + checkErr.Error()))
			return
		}

		for _, membership := range memberships {
			if !membership.IsMember {
				continue
			}
			addPost := database.AddPostToFriendGroupParams{
				GroupID: membership.GroupID,
				PostID:  addRequest.PostId,
			}
			addErr := queries.AddPostToFriendGroup(ctx.Request.Context(), addPost)
			if addErr != nil {
				ctx.String(http.StatusInternalServerError, "Error: Failed to add to friend group: "+addErr.Error())
				gin.DefaultWriter.Write([]byte("Failed to add to friend group: " + addErr.Error()))
				return
			}
		}

		ctx.JSON(http.StatusOK, gin.H{"success": "Added to groups"})
	}
}
