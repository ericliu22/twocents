package handlers

import (
	database "api/internal/core/db"
	"api/internal/core/fetch"
	"api/internal/core/utils"
	"api/internal/middleware"
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// PaginatedPostsResponse represents the response structure for paginated posts
type PaginatedPostsResponse struct {
	Posts      []PostWithMedia `json:"posts"`
	Offset	uuid.UUID		`json:"offset,omitempty"`
	HasMore    bool            `json:"hasMore"`
}

// PostWithMedia combines post metadata with its associated media
type PostWithMedia struct {
	Post  database.Post `json:"post"`
	Media any   `json:"media,omitempty"`
}

// GetGroupPostsHandler handles fetching paginated posts with media for a group
func GetGroupPostsHandler(queries *database.Queries) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// Authentication and user fetching
		token, tokenErr := middleware.GetAuthToken(ctx)
		if tokenErr != nil {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized access: " + tokenErr.Error()))
			log.Println("Unauthorized access: " + tokenErr.Error())
			return
		}
		user, userErr := queries.GetFirebaseId(ctx.Request.Context(), token.UID)
		if userErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to fetch user: "+userErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to fetch user: " + userErr.Error()))
			log.Println("Failed to fetch user: " + userErr.Error())
			return
		}

		// Get group ID from query parameters
		groupIDStr := ctx.Query("groupId")
		if groupIDStr == "" {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "groupId is required"})
			gin.DefaultWriter.Write([]byte("groupId is required"))
			log.Println("groupId is required")
			return
		}
		groupID, err := uuid.Parse(groupIDStr)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid groupId"})
			gin.DefaultWriter.Write([]byte("Invalid groupId: " + err.Error()))
			log.Println("Invalid groupId: " + err.Error())
			return
		}

		// Check membership
		checkMembership := database.CheckUserMembershipParams{
			GroupID: groupID,
			UserID:  user.ID,
		}
		isMember, checkErr := queries.CheckUserMembership(ctx.Request.Context(), checkMembership)
		if checkErr != nil {
			ctx.String(http.StatusInternalServerError, "Failed to check membership: "+checkErr.Error())
			gin.DefaultWriter.Write([]byte("Failed to check membership: " + checkErr.Error()))
			log.Println("Failed to check membership: " + checkErr.Error())
			return
		}
		if !isMember {
			ctx.String(http.StatusUnauthorized, "Unauthorized")
			gin.DefaultWriter.Write([]byte("Unauthorized access: User is not a member of the group"))
			log.Println("Unauthorized access: User is not a member of the group")
			return
		}
		// Get pagination parameters
		limitStr := ctx.DefaultQuery("limit", "10")
		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 || limit > 20 {
			limit = 10 // Default to 10 if invalid
		}

		offsetString := ctx.Query("offset") // Empty if not provided
		var offset uuid.UUID
		if offsetString != "" {
			var convErr error
			offset, convErr = uuid.Parse(offsetString) // Convert cursor to int if needed
			if convErr != nil {
				ctx.String(http.StatusBadRequest, "Invalid cursor")
				gin.DefaultWriter.Write([]byte("Invalid cursor: " + convErr.Error()))
				log.Println("Invalid cursor: " + convErr.Error())
				return
			}
		} else {
			topPost, topErr := queries.GetTopPost(ctx.Request.Context(), groupID)
			if topErr != nil {
				ctx.String(http.StatusInternalServerError, "Failed to fetch top post: "+topErr.Error())
				gin.DefaultWriter.Write([]byte("Failed to fetch top post: " + topErr.Error()))
				log.Println("Failed to fetch top post: " + topErr.Error())
				return
			}
			offset = topPost.Post.ID
		}
		// Create pagination params for the database query
		params := database.ListPaginatedPostsForGroupParams{
			GroupID: groupID,
			PostID: offset,
			Limit:   int32(limit + 1), // Fetch one extra to determine if there are more posts
		}

		// Retrieve posts for the group with pagination
		postLists, err := queries.ListPaginatedPostsForGroup(ctx.Request.Context(), params)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error: Failed to retrieve posts: "+err.Error())
			gin.DefaultWriter.Write([]byte("Error: Failed to retrieve posts: " + err.Error()))
			log.Println("Error: Failed to retrieve posts: " + err.Error())
			return
		}

		// Check if there are more posts
		hasMore := false
		if len(postLists) > limit {
			hasMore = true
			postLists = postLists[:limit] // Remove the extra post
		}

		// Process posts and fetch media
		postsWithMedia := make([]PostWithMedia, 0, len(postLists))
		var nextOffset uuid.UUID

		for i, post := range postLists {
			// Remember the last post ID for cursor
			if i == len(postLists)-1 {
				nextOffset = post.Post.ID
			}

			// Fetch media for the post
			var media any

			media = fetch.FetchMedia(ctx.Request.Context(), queries, post.Post)
			postsWithMedia = append(postsWithMedia, PostWithMedia{
				Post:  post.Post,
				Media: media,
			})
		}

		// Create response
		response := PaginatedPostsResponse{
			Posts:   postsWithMedia,
			HasMore: hasMore,
		}

		// Only include nextCursor if there are more posts
		if hasMore {
			response.Offset = nextOffset
		}

		// Generate JSON for response to compute an ETag
		responseJSON, err := json.Marshal(response)
		if err != nil {
			ctx.String(http.StatusInternalServerError, "Error generating response")
			gin.DefaultWriter.Write([]byte("Error generating response: " + err.Error()))
			log.Println("Error generating response: " + err.Error())
			return
		}

		if handled := utils.AttachCacheHeaders(ctx, responseJSON, 600); handled {
			return
		}

		// Send the fresh response
		ctx.JSON(http.StatusOK, response)
	}
}
