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
		uuid := uuid.New()
		newUser = database.CreateUserParams{
			ID:          uuid,
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
			UserID:   uuid,
			Username: registerRequest.Username,
		}
		userProfile, insertErr := queries.CreateUserProfile(ctx.Request.Context(), newUserProfile)
		if insertErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert user"})
			return
		}

		ctx.JSON(http.StatusOK, userProfile)
	}
}
