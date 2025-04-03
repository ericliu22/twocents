package score

import (
	database "api/internal/core/db"
	"context"
	"log"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

// calculateScore computes the score based on the given post.
func calcluateScore(post database.Post) float64 {
	freshnessScore := math.Exp(-0.1 * float64(time.Since(post.DateCreated.Time)))

	//score := (engagementScore*0.5 + freshnessScore*0.3 + interactionVelocity*0.2) * diversityPenalty
	return freshnessScore
}

func RoutineScoreCalculator(groupId uuid.UUID, queries *database.Queries) {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	// Run immediately if needed:
	for {
		select {
		case <-ticker.C:
			RunScoreCalculation(groupId, queries)
		}
	}
}

func RunScoreCalculation(groupId uuid.UUID, queries *database.Queries) {
	//@TODO: Make an actual context for this bitch
	posts, err := queries.ListPostsForGroup(context.Background(), groupId)
	if err != nil {
		log.Printf("Failed to fetch posts for calculation job")
		return
	}
	for _, post := range posts {
		score := calcluateScore(post.Post)
		var numeric pgtype.Numeric
		if err := numeric.Scan(score); err != nil {
			log.Printf("Failed to scan score into numeric type")
			return 
		}
		updateScore := database.UpdatePostScoreParams {
			Score: numeric,
		}
		queries.UpdatePostScore(context.Background(), updateScore)
	}
}
