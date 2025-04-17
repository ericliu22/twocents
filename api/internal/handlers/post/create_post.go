package handlers

import (
	database "api/internal/core/db"
	"api/internal/core/media"
	"api/internal/core/notifications"
	"api/internal/core/score"
	"api/internal/core/utils"
	"api/internal/middleware"
	"encoding/json"
	"net/http"

	"firebase.google.com/go/v4/messaging"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type CreatePostRequest struct {
	Media   string      `json:"media" binding:"required"`
	Caption *string     `json:"caption"`
	Groups  []uuid.UUID `json:"groups"`
}

func CreatePostHandler(queries *database.Queries, messagingClient *messaging.Client) gin.HandlerFunc {
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
		if err := ctx.Request.ParseMultipartForm(32 << 20); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "failed to parse multipart form: " + err.Error()})
		return
		}

		postValues, exists := ctx.Request.MultipartForm.Value["post"]
		if !exists || len(postValues) == 0 {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "missing post JSON data"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: missing post JSON data"))
			return
		}

		var createRequest CreatePostRequest
		if err := json.Unmarshal([]byte(postValues[0]), &createRequest); err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "invalid post JSON data: " + err.Error()})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + err.Error()))
			return
		}

		var postMedia database.MediaType
		switch createRequest.Media {
		case "IMAGE":
			postMedia = database.MediaTypeIMAGE
		case "VIDEO":
			postMedia = database.MediaTypeVIDEO
		case "LINK":
			postMedia = database.MediaTypeLINK
		case "TEXT":
			postMedia = database.MediaTypeTEXT
		case "OTHER":
			postMedia = database.MediaTypeOTHER
		}

		postParams := database.CreatePostParams{
			ID:          uuid.New(),
			UserID:      user.ID,
			Media:       postMedia,
			DateCreated: utils.PGTime(),
			Caption:     createRequest.Caption,
		}

		post, createErr := queries.CreatePost(ctx.Request.Context(), postParams)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to create post: "+createErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to create post: " + createErr.Error()))
			return
		}
		go media.CreateMedia(queries, &post, ctx)

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
		go notifications.SendPostNotification(
			queries,
			&post,
			createRequest.Groups,
			&user,
			messagingClient,
		)

		for _, groupID := range createRequest.Groups {
			go score.RunScoreCalculation(groupID, queries)
		}

		ctx.JSON(http.StatusOK, post)
	}
}
