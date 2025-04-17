package notifications

import (
	database "api/internal/core/db"
	"api/internal/core/utils"
	"context"
	"time"

	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
)

func SendPostNotification(
	queries *database.Queries,
	post *database.Post,
	groups []uuid.UUID,
	user *database.User,
	messagingClient *messaging.Client,
) {
	ctx, cancel := context.WithTimeout(context.Background(), 5 * time.Second)
	defer cancel()

	deviceTokens, err := queries.GetDeviceTokens(ctx, groups)
	if err != nil {
		cancel()
		return
	}
	tokens := utils.Flatten(deviceTokens)
	for _, token := range tokens {
		var body string
		if post.Caption != nil {
			body = *post.Caption
		} else {
			body = ""
		}
		notification := Notification{
			Token: token,
			Title: "New post from " + user.Username,
			Body:  body,
		}
		go func() {
			SendNotification(&notification, messagingClient)
		}()
	}
}
