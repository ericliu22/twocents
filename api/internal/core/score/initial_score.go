package score

import (
	database "api/internal/core/db"
	"context"
	"log"
)

func InitialScore(queries *database.Queries) {
	friendGroups, err := queries.ListFriendGroups(context.Background())
	if err != nil {
		log.Printf("Failed to fetch friend groups for calculation job")
		return
	}
	for _, friendGroup := range friendGroups {
		go RoutineScoreCalculator(friendGroup.ID, queries)
	}
}
