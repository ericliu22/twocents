package score

import (
	database "api/internal/core/db"
	"context"
	"log"

	"github.com/gin-gonic/gin"
)

func InitialScore(queries *database.Queries) {
	friendGroups, err := queries.ListFriendGroups(context.Background())
	if err != nil {
		log.Printf("Failed to fetch friend groups for calculation job")
		gin.DefaultWriter.Write([]byte("Failed to fetch friend groups for calculation job"))
		return
	}
	log.Printf("Fetched friend groups for calculation job")
	log.Printf("Friend groups: %v", friendGroups)
	for _, friendGroup := range friendGroups {
		go RoutineScoreCalculator(friendGroup.ID, queries)
	}
	gin.DefaultWriter.Write([]byte("Ran initial score"))
}
