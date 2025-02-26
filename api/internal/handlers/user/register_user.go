package handlers

import (
	database "api/internal/core/db"
	"net/http"
	"time"

	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type RegisterUserRequest struct {
	Username string `json:"username"`
}

func RegisterUserHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {

		var token auth.Token
		var ok bool

		value, keyExists := ctx.Get("user")
		if !keyExists {
			ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			gin.DefaultWriter.Write([]byte("Unauthorized"))
			return
		}

		token, ok = value.(auth.Token)
		if !ok {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read as token"})
			gin.DefaultWriter.Write([]byte("Failed to read as token"))
			return
		}

		uuid, parseErr := uuid.Parse(token.UID)
		if parseErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse as UUID"})
			gin.DefaultWriter.Write([]byte("Failed to parse as UUID"))
			return
		}

		userExists, queryErr := queries.CheckUser(ctx.Request.Context(), uuid)
		if queryErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query"})
			gin.DefaultWriter.Write([]byte("Failed to query"))
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
			gin.DefaultWriter.Write([]byte("Request body not as specified"))
			return
		}

		currentDate := pgtype.Date {
			Time: time.Now(),
			InfinityModifier: pgtype.Finite,
			Valid: true,
		}
		var newUser database.CreateUserParams
		newUser = database.CreateUserParams {
			ID: uuid,
			Provider: database.ProviderTypeEMAIL,
			DateCreated: currentDate,
			Username: registerRequest.Username,
		}
		_ , insertErr := queries.CreateUser(ctx.Request.Context(), newUser)
		if insertErr != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert user"})
			return
		}

		var newUserProfile database.CreateUserProfileParams
		newUserProfile = database.CreateUserProfileParams {
			UserID: uuid,
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
