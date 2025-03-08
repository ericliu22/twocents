package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type GetMediaRequest struct {
	PostId uuid.UUID `form:"postId"`
	Media database.MediaType `form:"media"`
}

func GetMediaHandler(queries *database.Queries) gin.HandlerFunc {
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

		var getRequest GetMediaRequest
		if bindErr := ctx.Bind(&getRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
			return
		}

		checkMembership := database.CheckUserMemberOfPostGroupsParams {
			UserID: user.ID,
			PostID: getRequest.PostId,
		}
		isMember, checkErr := queries.CheckUserMemberOfPostGroups(ctx.Request.Context(), checkMembership)
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
		var media any
		var mediaErr error
		switch getRequest.Media {
		case database.MediaTypeIMAGE:
			media, mediaErr = queries.GetImages(ctx.Request.Context(), getRequest.PostId)
		case database.MediaTypeVIDEO:
			media, mediaErr = queries.GetVideos(ctx.Request.Context(), getRequest.PostId)
		case database.MediaTypeLINK:
			media, mediaErr = queries.GetLinks(ctx.Request.Context(), getRequest.PostId)
		case database.MediaTypeTEXT:
			media, mediaErr = queries.GetLinks(ctx.Request.Context(), getRequest.PostId)
		}
		if mediaErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch media: " + mediaErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch media: " + mediaErr.Error()))
			return
		}

		ctx.JSON(http.StatusOK, media)
	}
}
