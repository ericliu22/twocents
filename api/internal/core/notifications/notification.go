package notifications

import (
	"encoding/json"
	"fmt"
	"os"

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

func SendNotification(deviceTokens []string, topic string, body APSBody) {

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
