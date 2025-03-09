package handlers

import (
	"api/internal/core/aws"
	database "api/internal/core/db"
	"api/internal/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
)

func UpdateProfilePicHandler(queries *database.Queries) gin.HandlerFunc {
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

		fileHeader, formErr := ctx.FormFile("file")
		if formErr != nil {
			ctx.String(http.StatusBadRequest, "Failed to get form file")
			gin.DefaultWriter.Write([]byte("File form is empty"))
			return
		}
		file, fileErr := fileHeader.Open()
		if fileErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to open file header as file")
			gin.DefaultWriter.Write([]byte("Failed to open file header as file" + fileErr.Error()))
			return
		}
		mediaURL, uploadErr := aws.ObjectUpload("profilepics/" + user.ID.String()+".jpeg", &file, "image/jpeg")
		if uploadErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to upload video to S3"+uploadErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to upload to S3" + uploadErr.Error()))
			return
		}

		profilepic := database.UpdateProfilePicParams {
			UserID: user.ID,
			ProfilePic: mediaURL,
		}
		err := queries.UpdateProfilePic(ctx.Request.Context(), profilepic)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Failed to update profile pic")
			gin.DefaultWriter.Write([]byte("Failed to create image" + err.Error()))
			return
		}
		ctx.JSON(http.StatusOK, gin.H{"success": "updated profile picture"})
	}
}
