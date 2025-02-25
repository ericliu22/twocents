package models

import (
	"github.com/google/uuid"
	"time"
)

type Media string

const (
	Image Media = "IMAGE"
	Video Media = "VIDEO"
	Other Media = "OTHER"
)

type Post struct {
	ID          uuid.UUID `json:"id"`
	Media       Media     `json:"media"`
	DateCreated time.Time `json:"dateCreated"`
	MediaUrl    string    `json:"mediaUrl"`
}
