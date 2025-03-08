package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type GetGroupPostsRequest struct {
	GroupId uuid.UUID `form:"groupId"`
}

func GetGroupPostsHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}
		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user: " + userErr.Error())
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

		checkMembership := database.CheckUserMembershipParams {
			GroupID: groupID,
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

		postLists, err := queries.ListPostsForGroup(ctx.Request.Context(), groupID)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve posts")
			gin.DefaultWriter.Write([]byte("Failed to retrieve posts: " + err.Error()))
			return
		}
		//DOGSHIT PLEASE FIX
		var posts []database.Post
		for _, post := range postLists {
			posts = append(posts, post.Post)
		}
		ctx.JSON(http.StatusOK, posts)
	}
}
