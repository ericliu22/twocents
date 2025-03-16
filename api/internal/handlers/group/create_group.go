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

type CreateGroupRequest struct {
	Name string `json:"name"`
}

func CreateGroupHandler(queries *database.Queries) gin.HandlerFunc {
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
		var createRequest CreateGroupRequest
		if bindErr := ctx.Bind(&createRequest); bindErr != nil {

			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			gin.DefaultWriter.Write([]byte("Request body not as specified: " + bindErr.Error()))
			return
		}

		currentTime := pgtype.Timestamp {
			Time:             utils.TwoCentsTime(),
			InfinityModifier: pgtype.Finite,
			Valid:            true,
		}
		createGroup := database.CreateFriendGroupParams{
			ID:          uuid.New(),
			Name:        createRequest.Name,
			DateCreated: currentTime,
			OwnerID:     user.ID,
		}

		friendGroup, createErr := queries.CreateFriendGroup(ctx.Request.Context(), createGroup)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to create group: "+createErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to create group: " + createErr.Error()))
			return
		}

		addUser := database.AddUserToGroupParams{
			GroupID:  friendGroup.ID,
			UserID:   user.ID,
			JoinedAt: currentTime,
			Role:     database.GroupRoleADMIN,
		}
		_, addErr := queries.AddUserToGroup(ctx.Request.Context(), addUser)
		if addErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to add user: "+addErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to add user: " + addErr.Error()))
			return

		}

		ctx.JSON(http.StatusOK, friendGroup)
	}
}
