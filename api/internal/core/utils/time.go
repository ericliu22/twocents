package utils


import (
	"time"
)

func TwoCentsTime() time.Time {
	now := time.Now().UTC()
	return now
}
