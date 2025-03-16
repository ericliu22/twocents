package utils


import (
	"fmt"
	"time"
)

func TwoCentsTime() time.Time {
	now := time.Now()
	// Format the time as a string in the desired layout.
	formatted := now.Format("2006-01-02 15:04:05")
	// Parse the formatted string back into a time.Time.
	t, err := time.Parse("2006-01-02 15:04:05", formatted)
	if err != nil {
		// In production, handle the error appropriately.
		panic(err)
	}
	return t
}
