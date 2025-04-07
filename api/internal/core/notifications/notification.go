package notifications

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"firebase.google.com/go/v4/messaging"
	"github.com/gin-gonic/gin"
	"github.com/sideshow/apns2"
)

// https://developer.apple.com/documentation/usernotifications/generating-a-remote-notification
type APSBody struct {
	APSAlert         Alert   `json:"alert" binding:"required"`
	Badge            *int    `json:"badge"`
	Sound            *string `json:"sound"`
	ThreadId         *string `json:"thread-id"`
	Category         *string `json:"category"`
	ContentAvailable *int    `json:"content-available"`
}

type Notification struct {
	Token string            `json:"token"`           // Device Token
	Title string            `json:"title"`           // Match the JSON field "title"
	Body  string            `json:"body"`            // Match the JSON field "body"
	Image *string           `json:"image,omitempty"` // Optional image field
	Data  map[string]string `json:"data"`            // Optional data
}

func SendNotification(notification *Notification, messagingClient *messaging.Client) {
	sendFcmNotification(notification, messagingClient)
}

func sendFcmNotification(notification *Notification, messagingClient *messaging.Client) {
	sendSingleNotification(notification, messagingClient)
}

func sendApsNotification(deviceTokens []string, topic string, body APSBody) {
	payload, encodingErr := json.Marshal(body)
	if encodingErr != nil {
		gin.DefaultWriter.Write([]byte("Error encoding payload: " + encodingErr.Error()))
		return
	}
	for _, token := range deviceTokens {
		notification := &apns2.Notification{
			DeviceToken: token,
			Topic:       topic,
			Payload:     payload,
		}

		var client *apns2.Client
		if os.Getenv("DEPLOYMENT_ENVIORNMENT") == "PRODUCTION" {
			client = apns2.NewClient(cert).Production()
		} else {
			client = apns2.NewClient(cert).Development()
		}
		res, err := client.Push(notification)

		if err != nil {
			gin.DefaultWriter.Write([]byte("Error sending notification: " + err.Error()))
		}
		fmt.Printf("%v %v %v\n", res.StatusCode, res.ApnsID, res.Reason)
	}

}

func sendSingleNotification(notification *Notification, messagingClient *messaging.Client) error {
	// Build the FCM message
	msg := &messaging.Message{
		Token: notification.Token,
		Notification: &messaging.Notification{
			Title: notification.Title,
			Body:  notification.Body,
		},
		Data: notification.Data,
	}

	// If an image was provided, include it
	if notification.Image != nil && *notification.Image != "" {
		msg.Notification.ImageURL = *notification.Image
	}

	// Send the message
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	response, err := messagingClient.Send(ctx, msg)
	if err != nil {
		log.Printf("Error sending single notification to token '%s': %v\n", notification.Token, err)
		cancel()
		return err
	}

	log.Printf("Successfully sent notification to token '%s'. FCM response: %s\n", notification.Token, response)
	return nil
}
