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

		var getRequest GetGroupPostsRequest
		if bindErr := ctx.ShouldBindQuery(&getRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
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

		postLists, err := queries.ListPostsForGroup(ctx.Request.Context(), getRequest.GroupId)
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
