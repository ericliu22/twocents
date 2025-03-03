package handlers

import (
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type CreatePostRequest struct {
	Media   string  `json:"media"`
	Caption *string `json:"caption"`
}

func CreatePostHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		//@TODO: Maybe add some permissions here
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			return
		}
		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user"+userErr.Error())
			return
		}

		postParams := database.CreatePostParams{
			ID:     uuid.New(),
			UserID: user.ID,
		}

		post, createErr := queries.CreatePost(ctx.Request.Context(), postParams)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to create post"+createErr.Error())
		}
		ctx.JSON(http.StatusOK, post)
	}
}
