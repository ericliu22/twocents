package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type AddMemberRequest struct {
	FriendId string `json:"friendId"`
	GroupId  string `json:"groupId"`
}

func AddMemberHandler(queries *database.Queries) gin.HandlerFunc {
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

		var addRequest AddMemberRequest
		if bindErr := ctx.Bind(&addRequest); bindErr != nil {

			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
			return
		}

		friendUUID, parseErr := uuid.Parse(addRequest.FriendId)
		if parseErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse as UUID"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + parseErr.Error()))
			return
		}

		getFriendship := database.GetFriendshipParams{
			UserID:   user.ID,
			FriendID: friendUUID,
		}
		friendship, friendErr := queries.GetFriendship(ctx.Request.Context(), getFriendship)
		if friendErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get friendship status"})
			gin.DefaultWriter.Write([]byte("Failed to get friendship status" + friendErr.Error()))
			return
		}

		if friendship.Status != database.FriendshipStatusACCEPTED {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}

		currentDate := pgtype.Date{
			Time:             time.Now(),
			InfinityModifier: pgtype.Finite,
			Valid:            true,
		}
		groupUUID, parseErr := uuid.Parse(addRequest.GroupId)
		if parseErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse as UUID"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + parseErr.Error()))
			return
		}

		addMember := database.AddUserToGroupParams{
			GroupID:  groupUUID,
			UserID:   friendUUID,
			JoinedAt: currentDate,
			Role:     database.GroupRoleMEMBER,
		}

		friendGroup, addErr := queries.AddUserToGroup(ctx.Request.Context(), addMember)
		if addErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add to group"})
			gin.DefaultWriter.Write([]byte("Failed to add to group: " + addErr.Error()))
		}

		ctx.JSON(http.StatusOK, friendGroup)
	}
}
