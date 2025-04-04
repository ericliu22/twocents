package score

import (
	database "api/internal/core/db"
	"context"
	"log"
	"math"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

// calculateScore computes the score based on the given post.
func calcluateScore(post database.Post) float64 {
	freshnessScore := math.Exp(-0.1 * time.Since(post.DateCreated.Time).Hours())

	//score := (engagementScore*0.5 + freshnessScore*0.3 + interactionVelocity*0.2) * diversityPenalty
	return freshnessScore
}

func RoutineScoreCalculator(groupId uuid.UUID, queries *database.Queries) {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	// Run immediately if needed:
	RunScoreCalculation(groupId, queries)
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
		numeric, err := Float64ToPgNumeric(score)
		if err != nil {
			log.Printf("Failed to convert score to pgtype.Numeric: %v", err)
			return
		}
		updateScore := database.UpdatePostScoreParams {
			Score: numeric,
		}
		if err := queries.UpdatePostScore(context.Background(), updateScore); err != nil {
			log.Printf("Failed to update post score: %v", err)
			return
		}

	}
}

func Float64ToPgNumeric(f float64) (pgtype.Numeric, error) {
	str := strconv.FormatFloat(f, 'f', -1, 64)

	var numeric pgtype.Numeric
	err := numeric.Scan(str)
	return numeric, err
}
