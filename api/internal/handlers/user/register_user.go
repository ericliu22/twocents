package handlers

import (
	database "api/internal/core/db"
	"api/internal/core/utils"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type RegisterUserRequest struct {
	Username string `json:"username"`
}

func RegisterUserHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			return
		}

		userExists, queryErr := queries.CheckFirebaseId(ctx.Request.Context(), token.UID)
		if queryErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query"})
			return
		}
		if userExists {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "User already exists"})
			gin.DefaultWriter.Write([]byte("User already exists"))
			return
		}

		var registerRequest RegisterUserRequest
		if bindErr := ctx.Bind(&registerRequest); bindErr != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Request body not as specified"})
			return
		}

		var newUser database.CreateUserParams
		userId := uuid.New()
		newUser = database.CreateUserParams{
			ID:          userId,
			FirebaseUid: token.UID,
			Provider:    database.ProviderTypeEMAIL,
			DateCreated: utils.PGTime(),
			Username:    registerRequest.Username,
		}
		_, insertErr := queries.CreateUser(ctx.Request.Context(), newUser)
		if insertErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert user"})
			return
		}

		var newUserProfile database.CreateUserProfileParams
		newUserProfile = database.CreateUserProfileParams{
			UserID:   userId,
			Username: registerRequest.Username,
		}
		userProfile, insertErr := queries.CreateUserProfile(ctx.Request.Context(), newUserProfile)
		if insertErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert user"})
			return
		}

		//TEMPORARILY
		groupId, err := uuid.Parse("b343342a-d41b-4c79-a8a8-7e0b142be6da")
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse groupId"})
			return
		}
		addUser := database.AddUserToGroupParams{
			GroupID:  groupId,
			UserID:   userId,
			Role:     database.GroupRoleMEMBER,
			JoinedAt: utils.PGTime(),
		}

		_, addErr := queries.AddUserToGroup(ctx.Request.Context(), addUser)
		if addErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add user to group"})
			return
		}

		ctx.JSON(http.StatusOK, userProfile)
	}
}
