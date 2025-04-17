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

func GetMediaHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}
		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user: "+userErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch user: " + userErr.Error()))
			return
		}

		postIDStr := ctx.Query("postId")
		if postIDStr == "" {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "postId is required"})
			gin.DefaultWriter.Write([]byte("Failed to query postId"))
			return
		}

		postID, err := uuid.Parse(postIDStr)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid groupId"})
			gin.DefaultWriter.Write([]byte("Failed to parse groupId"))
			return
		}

		mediaStr := database.MediaType(ctx.Query("media"))

		checkMembership := database.CheckUserMemberOfPostGroupsParams{
			UserID: user.ID,
			PostID: postID,
		}
		isMember, checkErr := queries.CheckUserMemberOfPostGroups(ctx.Request.Context(), checkMembership)
		if checkErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to check membership: "+checkErr.Error())
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
		switch mediaStr {
		case database.MediaTypeIMAGE:
			media, mediaErr = queries.GetImages(ctx.Request.Context(), postID)
		case database.MediaTypeVIDEO:
			media, mediaErr = queries.GetVideos(ctx.Request.Context(), postID)
		case database.MediaTypeLINK:
			media, mediaErr = queries.GetLinks(ctx.Request.Context(), postID)
		case database.MediaTypeTEXT:
			media, mediaErr = queries.GetTexts(ctx.Request.Context(), postID)
		}
		if mediaErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch media: "+mediaErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch media: " + mediaErr.Error()))
			return
		}

		mediaJson, err := json.Marshal(media)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error generating response")
			return
		}

		if handled := utils.AttachCacheHeaders(ctx, mediaJson, 30); handled {
			return
		}

		ctx.JSON(http.StatusOK, media)
	}
}
