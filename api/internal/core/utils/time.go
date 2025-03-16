package utils

import (
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

func TwoCentsTime() time.Time {
	now := time.Now().UTC()
	return now
}

func PGTime() pgtype.Timestamptz {
	currentTime := pgtype.Timestamptz{
		Time:             TwoCentsTime(),
		InfinityModifier: pgtype.Finite,
		Valid:            true,
	}
	return currentTime
}
