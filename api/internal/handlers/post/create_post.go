package handlers

import (
	database "api/internal/core/db"
	"api/internal/core/utils"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type CreatePostRequest struct {
	Media   string      `json:"media" binding:"required"`
	Caption *string     `json:"caption"`
	Groups  []uuid.UUID `json:"groups"`
}

func CreatePostHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		//@TODO: Maybe add some permissions here
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

		var createRequest CreatePostRequest
		if bindErr := ctx.ShouldBindJSON(&createRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + ctx.ContentType()))
			return
		}

		var media database.MediaType
		switch createRequest.Media {
		case "IMAGE":
			media = database.MediaTypeIMAGE
		case "VIDEO":
			media = database.MediaTypeVIDEO
		case "LINK":
			media = database.MediaTypeLINK
		case "TEXT":
			media = database.MediaTypeTEXT
		case "OTHER":
			media = database.MediaTypeOTHER
		}
		gin.DefaultWriter.Write([]byte("USERID: " + user.ID.String()))
		postParams := database.CreatePostParams{
			ID:          uuid.New(),
			UserID:      user.ID,
			Media:       media,
			DateCreated: utils.PGTime(),
			Caption:     createRequest.Caption,
		}

		post, createErr := queries.CreatePost(ctx.Request.Context(), postParams)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to create post: "+createErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to create post: " + createErr.Error()))
			return
		}

		checkMembership := database.CheckUserMembershipForGroupsParams{
			UserID:  user.ID,
			Column2: createRequest.Groups,
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
				PostID:  post.ID,
			}
			addErr := queries.AddPostToFriendGroup(ctx.Request.Context(), addPost)
			if addErr != nil {
				ctx.String(http.StatusInternalServerError, "Error: Failed to add to friend group: "+addErr.Error())
				gin.DefaultWriter.Write([]byte("Failed to add to friend group: " + addErr.Error()))
				return
			}
		}

		ctx.JSON(http.StatusOK, post)
	}
}
