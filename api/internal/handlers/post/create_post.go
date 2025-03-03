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

type CreatePostRequest struct {
	Media   string  `json:"media" binding:"required"`
	Caption *string `json:"caption"`
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
			ctx.String(http.StatusInternalServerError, "Failed to fetch user"+userErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch user"+userErr.Error()))
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
		case "OTHER":
			media = database.MediaTypeOTHER
		}
		currentDate := pgtype.Date{
			Time:             time.Now(),
			InfinityModifier: pgtype.Finite,
			Valid:            true,
		}
		gin.DefaultWriter.Write([]byte("USERID: " + user.ID.String()))
		postParams := database.CreatePostParams{
			ID:     uuid.New(),
			UserID: user.ID,
			Media: media,
			DateCreated: currentDate,
			Caption: createRequest.Caption,
		}

		post, createErr := queries.CreatePost(ctx.Request.Context(), postParams)
		if createErr != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to create post: "+createErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to create post: "+createErr.Error()))
		}
		ctx.JSON(http.StatusOK, post)
	}
}
