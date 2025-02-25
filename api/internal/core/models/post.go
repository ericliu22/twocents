package models

import (
	"time"
	"github.com/google/uuid"
)

type Media string
const (
	Image   Media = "IMAGE"
	Video Media = "VIDEO"
	Other  Media = "OTHER"
)

type Post struct {
	ID        uuid.UUID
	Media     Media
	DateCreated time.Time
	MediaUrl  string
}
